const express = require('express');
const cors = require('cors');
const AWS = require('aws-sdk');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Configure AWS SDK
// AWS credentials should be set via environment variables or IAM role
// For local development, use AWS credentials file or environment variables
AWS.config.update({
  region: process.env.AWS_REGION || 'us-east-1'
});

// Initialize Lex Runtime V2 client
const lexRuntime = new AWS.LexRuntimeV2();

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Chatbot backend service is running' });
});

// Chat endpoint - proxies requests to Lex V2
app.post('/api/chat', async (req, res) => {
  try {
    const { botId, botAliasId, localeId, sessionId, text, region } = req.body;

    // Validate required parameters
    if (!botId || !botAliasId || !localeId || !sessionId || !text) {
      return res.status(400).json({
        error: 'Missing required parameters',
        required: ['botId', 'botAliasId', 'localeId', 'sessionId', 'text']
      });
    }

    // Update AWS region if provided
    if (region) {
      AWS.config.update({ region });
      lexRuntime.config.update({ region });
    }

    // Prepare Lex V2 request
    const params = {
      botId: botId,
      botAliasId: botAliasId,
      localeId: localeId,
      sessionId: sessionId,
      text: text
    };

    console.log('Sending to Lex:', { botId, botAliasId, localeId, sessionId, textLength: text.length });

    // Call Lex V2 RecognizeText API
    const response = await lexRuntime.recognizeText(params).promise();

    console.log('Lex response:', JSON.stringify(response, null, 2));

    // Format response for frontend
    const formattedResponse = {
      messages: response.messages || [],
      sessionId: response.sessionId,
      sessionState: response.sessionState
    };

    res.json(formattedResponse);

  } catch (error) {
    console.error('Error calling Lex:', error);

    // Handle specific AWS errors
    if (error.code === 'ResourceNotFoundException') {
      return res.status(404).json({
        error: 'Bot not found',
        message: 'Please verify that the Bot ID, Alias ID, and Locale ID are correct.'
      });
    }

    if (error.code === 'AccessDeniedException') {
      return res.status(403).json({
        error: 'Access denied',
        message: 'AWS credentials do not have permission to access Lex. Please check your IAM permissions.'
      });
    }

    if (error.code === 'ThrottlingException') {
      return res.status(429).json({
        error: 'Rate limit exceeded',
        message: 'Too many requests. Please try again later.'
      });
    }

    // Generic error response
    res.status(500).json({
      error: 'Internal server error',
      message: error.message || 'An error occurred while processing your request.'
    });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Chatbot backend server running on http://localhost:${PORT}`);
  console.log(`📝 Health check: http://localhost:${PORT}/health`);
  console.log(`💬 Chat endpoint: http://localhost:${PORT}/api/chat`);
  console.log(`\n⚠️  Make sure AWS credentials are configured:`);
  console.log(`   - AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables`);
  console.log(`   - Or AWS credentials file (~/.aws/credentials)`);
  console.log(`   - Or IAM role (if running on EC2)`);
});

