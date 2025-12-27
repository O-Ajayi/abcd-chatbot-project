"""
Chatbot Analyzer Lambda Function
Connects to RDS instance to analyze conversation data
"""
import json
import os
import logging
import psycopg2
from psycopg2 import pool
from typing import Dict, Any, List

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
    Lambda handler for analyzing conversation data
    
    Expected event structure:
    {
        "sessionId": "string",
        "analysisType": "string"  # "sentiment", "intent_distribution", "session_summary"
    }
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    conn = None
    try:
        session_id = event.get('sessionId', '')
        analysis_type = event.get('analysisType', 'session_summary')
        
        # Get database connection
        conn = get_db_connection()
        cursor = conn.cursor()
        
        if analysis_type == 'session_summary':
            # Get session summary
            cursor.execute("""
                SELECT 
                    COUNT(*) as interaction_count,
                    array_agg(DISTINCT intent) as intents,
                    MIN(created_at) as session_start,
                    MAX(created_at) as session_end
                FROM chatbot_interactions
                WHERE session_id = %s
            """, (session_id,))
            
            result = cursor.fetchone()
            analysis_result = {
                'sessionId': session_id,
                'interactionCount': result[0],
                'intents': result[1] if result[1] else [],
                'sessionStart': result[2].isoformat() if result[2] else None,
                'sessionEnd': result[3].isoformat() if result[3] else None
            }
            
        elif analysis_type == 'intent_distribution':
            # Get intent distribution
            cursor.execute("""
                SELECT intent, COUNT(*) as count
                FROM chatbot_interactions
                WHERE session_id = %s
                GROUP BY intent
                ORDER BY count DESC
            """, (session_id,))
            
            results = cursor.fetchall()
            analysis_result = {
                'sessionId': session_id,
                'intentDistribution': [
                    {'intent': row[0], 'count': row[1]} 
                    for row in results
                ]
            }
            
        else:
            # Default: sentiment analysis (placeholder)
            analysis_result = {
                'sessionId': session_id,
                'sentiment': 'neutral',
                'confidence': 0.5
            }
        
        logger.info(f"Analysis completed for session: {session_id}")
        
        return {
            'statusCode': 200,
            'body': json.dumps(analysis_result)
        }
        
    except Exception as e:
        logger.error(f"Error analyzing conversation: {str(e)}")
        
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

