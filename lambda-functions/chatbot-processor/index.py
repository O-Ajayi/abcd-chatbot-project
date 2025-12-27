"""
Chatbot Processor Lambda Function
Connects to RDS instance to process chatbot interactions
"""
import json
import os
import logging
import psycopg2
from psycopg2 import pool
from typing import Dict, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Connection pool for RDS
connection_pool = None

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
    Lambda handler for processing chatbot interactions
    
    Expected event structure:
    {
        "sessionId": "string",
        "inputText": "string",
        "intent": "string",
        "slots": {}
    }
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    conn = None
    try:
        # Extract event data
        session_id = event.get('sessionId', '')
        input_text = event.get('inputText', '')
        intent = event.get('intent', '')
        slots = event.get('slots', {})
        
        # Get database connection
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Store interaction in database
        cursor.execute("""
            INSERT INTO chatbot_interactions 
            (session_id, input_text, intent, slots, created_at)
            VALUES (%s, %s, %s, %s, NOW())
            ON CONFLICT DO NOTHING
        """, (session_id, input_text, intent, json.dumps(slots)))
        
        conn.commit()
        logger.info(f"Stored interaction for session: {session_id}")
        
        # Process the interaction (example logic)
        response_text = process_interaction(intent, slots, input_text)
        
        # Update interaction with response
        cursor.execute("""
            UPDATE chatbot_interactions
            SET response_text = %s, updated_at = NOW()
            WHERE session_id = %s
            ORDER BY created_at DESC
            LIMIT 1
        """, (response_text, session_id))
        
        conn.commit()
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': response_text,
                'sessionId': session_id,
                'intent': intent
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing interaction: {str(e)}")
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

def process_interaction(intent: str, slots: Dict, input_text: str) -> str:
    """Process the interaction based on intent"""
    if intent == 'GreetingIntent':
        return "Hello! How can I help you today?"
    elif intent == 'HelpIntent':
        return "I'm here to help! What would you like to know?"
    elif intent == 'GoodbyeIntent':
        return "Goodbye! Have a great day!"
    else:
        return f"I received your message: {input_text}. How can I assist you?"

