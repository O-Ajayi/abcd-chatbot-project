"""
Chatbot Reviewer Lambda Function
Connects to DynamoDB tables and RDS instance to review conversations
"""
import json
import os
import logging
import boto3
import psycopg2
from psycopg2 import pool
from typing import Dict, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# DynamoDB client
dynamodb = boto3.resource('dynamodb')

# Connection pool for RDS
connection_pool = None

def get_dynamodb_table(table_name: str):
    """Get DynamoDB table"""
    return dynamodb.Table(table_name)

def get_db_connection():
    """Get database connection from pool"""
    global connection_pool
    
    if connection_pool is None:
        try:
            rds_endpoint = os.environ.get('RDS_ENDPOINT', '')
            rds_username = os.environ.get('RDS_USERNAME', 'chatbotadmin')
            rds_password = os.environ.get('RDS_PASSWORD', '')
            rds_database = os.environ.get('RDS_DATABASE_NAME', 'chatbotdb')
            
            # Parse endpoint (format: host:port)
            if ':' in rds_endpoint:
                host, port = rds_endpoint.split(':')
            else:
                host = rds_endpoint
                port = 5432
            
            connection_pool = psycopg2.pool.SimpleConnectionPool(
                1, 10,
                host=host,
                port=port,
                database=rds_database,
                user=rds_username,
                password=rds_password
            )
            logger.info("Database connection pool created")
        except Exception as e:
            logger.error(f"Error creating connection pool: {str(e)}")
            raise
    
    return connection_pool.getconn()

def return_db_connection(conn):
    """Return connection to pool"""
    global connection_pool
    if connection_pool:
        connection_pool.putconn(conn)

def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for reviewing conversations
    Processes messages from SQS and stores reviews in DynamoDB and RDS
    
    Expected event structure (from SQS):
    {
        "Records": [
            {
                "body": "{\"conversationId\": \"string\", \"review\": \"string\", \"rating\": 5}"
            }
        ]
    }
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Get table names from environment
    history_table_name = os.environ.get('DYNAMODB_HISTORY_TABLE', '')
    reviewer_table_name = os.environ.get('DYNAMODB_REVIEWER_TABLE', '')
    
    history_table = get_dynamodb_table(history_table_name) if history_table_name else None
    reviewer_table = get_dynamodb_table(reviewer_table_name) if reviewer_table_name else None
    
    conn = None
    processed_count = 0
    failed_count = 0
    
    try:
        # Process SQS records
        for record in event.get('Records', []):
            try:
                # Parse SQS message body
                body = json.loads(record.get('body', '{}'))
                conversation_id = body.get('conversationId', '')
                review_text = body.get('review', '')
                rating = body.get('rating', 0)
                review_id = body.get('reviewId', f"review-{conversation_id}-{context.aws_request_id}")
                
                # Store review in DynamoDB
                if reviewer_table:
                    reviewer_table.put_item(
                        Item={
                            'review_id': review_id,
                            'conversation_id': conversation_id,
                            'review': review_text,
                            'rating': rating,
                            'created_at': context.aws_request_id,
                            'timestamp': str(context.aws_request_id)
                        }
                    )
                    logger.info(f"Stored review in DynamoDB: {review_id}")
                
                # Get conversation history from DynamoDB
                conversation_data = None
                if history_table:
                    try:
                        response = history_table.get_item(
                            Key={'conversation_id': conversation_id}
                        )
                        conversation_data = response.get('Item', {})
                    except Exception as e:
                        logger.warning(f"Could not retrieve conversation history: {str(e)}")
                
                # Store review summary in RDS
                conn = get_db_connection()
                cursor = conn.cursor()
                
                cursor.execute("""
                    INSERT INTO conversation_reviews 
                    (review_id, conversation_id, review_text, rating, conversation_data, created_at)
                    VALUES (%s, %s, %s, %s, %s, NOW())
                    ON CONFLICT (review_id) DO UPDATE
                    SET review_text = EXCLUDED.review_text,
                        rating = EXCLUDED.rating,
                        updated_at = NOW()
                """, (
                    review_id,
                    conversation_id,
                    review_text,
                    rating,
                    json.dumps(conversation_data) if conversation_data else None
                ))
                
                conn.commit()
                logger.info(f"Stored review in RDS: {review_id}")
                processed_count += 1
                
            except Exception as e:
                logger.error(f"Error processing record: {str(e)}")
                failed_count += 1
                if conn:
                    conn.rollback()
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'processed': processed_count,
                'failed': failed_count,
                'message': f'Processed {processed_count} reviews, {failed_count} failed'
            })
        }
        
    except Exception as e:
        logger.error(f"Error in reviewer handler: {str(e)}")
        if conn:
            conn.rollback()
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        }
    finally:
        if conn:
            return_db_connection(conn)

