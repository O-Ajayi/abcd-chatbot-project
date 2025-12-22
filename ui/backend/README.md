# Chatbot Backend Service

Backend proxy service that handles AWS authentication and proxies requests to AWS Lex V2.

## Purpose

This service acts as a secure proxy between the Angular frontend and AWS Lex V2. It handles:
- AWS credential management (never exposed to frontend)
- Lex V2 API calls
- Error handling and response formatting
- CORS configuration

## Prerequisites

- Node.js 14+ installed
- AWS credentials configured
- AWS Lex V2 bot deployed

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure AWS Credentials

You have three options:

#### Option A: Environment Variables

```bash
export AWS_ACCESS_KEY_ID=your-access-key-id
export AWS_SECRET_ACCESS_KEY=your-secret-access-key
export AWS_REGION=us-east-1
```

#### Option B: AWS Credentials File

Create `~/.aws/credentials`:

```ini
[default]
aws_access_key_id = your-access-key-id
aws_secret_access_key = your-secret-access-key
```

And `~/.aws/config`:

```ini
[default]
region = us-east-1
```

#### Option C: IAM Role (if running on EC2)

If running on an EC2 instance, use an IAM role with appropriate permissions.

### 3. Configure Environment Variables (Optional)

```bash
cp .env.example .env
# Edit .env with your settings
```

### 4. Start the Server

```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start
```

The server will start on `http://localhost:3000`

## API Endpoints

### Health Check

```
GET /health
```

Returns server status.

### Chat Endpoint

```
POST /api/chat
Content-Type: application/json

{
  "botId": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
  "botAliasId": "TSTALIASID",
  "localeId": "en_US",
  "sessionId": "session-1234567890-abc123",
  "text": "Hello",
  "region": "us-east-1"
}
```

**Response:**

```json
{
  "messages": [
    {
      "content": "Hello! How can I help you?",
      "contentType": "PlainText"
    }
  ],
  "sessionId": "session-1234567890-abc123",
  "sessionState": { ... }
}
```

## Required IAM Permissions

The AWS credentials/role must have the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lex:RecognizeText",
        "lex:RecognizeUtterance"
      ],
      "Resource": "*"
    }
  ]
}
```

## Troubleshooting

### Error: "Access Denied"

- Verify AWS credentials are correct
- Check IAM permissions for Lex V2
- Ensure the region is correct

### Error: "Bot not found"

- Verify Bot ID and Bot Alias ID are correct
- Check that the bot is published to the alias
- Ensure the locale ID matches

### Error: "Rate limit exceeded"

- Lex V2 has rate limits
- Implement retry logic with exponential backoff
- Consider using provisioned capacity for production

### CORS Issues

If you encounter CORS errors, the backend is already configured to allow all origins in development. For production, configure CORS_ORIGIN in `.env`.

## Production Deployment

For production deployment:

1. Use environment variables for configuration
2. Set up proper CORS origins
3. Use HTTPS
4. Implement rate limiting
5. Add authentication/authorization
6. Set up logging and monitoring
7. Use process manager (PM2, systemd, etc.)

## Security Notes

- Never commit AWS credentials to version control
- Use IAM roles when possible
- Implement proper authentication for production
- Use HTTPS in production
- Validate and sanitize all inputs

