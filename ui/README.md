# Chatbot UI - Angular Application

This directory contains the Angular frontend application and Node.js backend proxy service for testing your AWS Lex V2 chatbot.

## 📁 Directory Structure

```
ui/
├── angular-ui/          # Angular frontend application
│   ├── src/
│   │   ├── app/
│   │   │   ├── app.component.ts
│   │   │   ├── app.component.html
│   │   │   ├── app.component.scss
│   │   │   └── services/
│   │   │       ├── chat.service.ts
│   │   │       └── config.service.ts
│   │   ├── index.html
│   │   ├── main.ts
│   │   └── styles.scss
│   ├── package.json
│   ├── angular.json
│   └── tsconfig.json
│
└── backend/             # Node.js backend proxy service
    ├── server.js
    ├── package.json
    ├── .env.example
    └── README.md
```

## 🚀 Quick Start

### Prerequisites

- Node.js 14+ and npm
- Angular CLI (will be installed locally)
- AWS credentials configured
- Terraform infrastructure deployed

### Step 1: Get Your Bot Information

After deploying your Terraform infrastructure, get the Bot ID and Alias ID:

```bash
cd terraform
terraform output lex_bot_id
terraform output lex_bot_alias_id
```

### Step 2: Set Up Backend Service

```bash
cd backend
npm install
```

Configure AWS credentials (see `backend/README.md` for details):

```bash
# Option 1: Environment variables
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
export AWS_REGION=us-east-1

# Option 2: AWS credentials file (~/.aws/credentials)
```

Start the backend server:

```bash
npm start
# Server runs on http://localhost:3000
```

### Step 3: Set Up Angular Frontend

Open a new terminal:

```bash
cd angular-ui
npm install
```

Start the Angular development server:

```bash
npm start
# Application runs on http://localhost:4200
```

### Step 4: Configure and Test

1. Open `http://localhost:4200` in your browser
2. Enter your Bot ID and Bot Alias ID from Step 1
3. Configure Locale ID (default: `en_US`) and Region (default: `us-east-1`)
4. Start chatting!

## 🏗️ Architecture

```
┌─────────────────┐
│  Angular UI     │
│  (Port 4200)    │
└────────┬────────┘
         │ HTTP
         │
         ▼
┌─────────────────┐
│  Backend Proxy │
│  (Port 3000)    │
└────────┬────────┘
         │ AWS SDK
         │
         ▼
┌─────────────────┐
│   AWS Lex V2    │
│   (AWS Cloud)   │
└─────────────────┘
```

## 📝 Features

### Angular Frontend

- **Modern UI**: Clean, responsive design with gradient styling
- **Real-time Chat**: Send and receive messages in real-time
- **Configuration Management**: Save bot configuration in localStorage
- **Session Management**: Automatic session ID generation
- **Typing Indicators**: Visual feedback while waiting for responses
- **Error Handling**: User-friendly error messages
- **Clear Chat**: Reset conversation with one click

### Backend Service

- **Secure Proxy**: AWS credentials never exposed to frontend
- **Error Handling**: Comprehensive error handling and user-friendly messages
- **CORS Support**: Configured for development
- **Health Check**: Endpoint to verify service status
- **Logging**: Console logging for debugging

## 🔧 Configuration

### Backend Configuration

Edit `backend/.env` or set environment variables:

```env
AWS_REGION=us-east-1
PORT=3000
```

### Frontend Configuration

The Angular app stores configuration in browser localStorage. Configuration is automatically saved when you update the Bot ID, Alias ID, Locale ID, or Region in the UI.

To change the backend API URL, edit `angular-ui/src/app/services/chat.service.ts`:

```typescript
private apiUrl = 'http://localhost:3000/api'; // Change this for production
```

## 🧪 Testing

### Test the Backend

```bash
# Health check
curl http://localhost:3000/health

# Test chat endpoint
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "botId": "your-bot-id",
    "botAliasId": "your-alias-id",
    "localeId": "en_US",
    "sessionId": "test-session",
    "text": "Hello",
    "region": "us-east-1"
  }'
```

### Test the Frontend

1. Ensure backend is running
2. Open Angular app in browser
3. Configure Bot ID and Alias ID
4. Send test messages

## 🐛 Troubleshooting

### Backend Issues

**Error: "Access Denied"**
- Verify AWS credentials are configured correctly
- Check IAM permissions for Lex V2

**Error: "Bot not found"**
- Verify Bot ID and Alias ID are correct
- Ensure bot is published to the alias

**Port already in use**
- Change PORT in `.env` or environment variable
- Kill process using port 3000: `lsof -ti:3000 | xargs kill`

### Frontend Issues

**Cannot connect to backend**
- Ensure backend is running on port 3000
- Check CORS configuration
- Verify API URL in `chat.service.ts`

**Configuration not saving**
- Check browser localStorage is enabled
- Clear browser cache and try again

**Messages not appearing**
- Check browser console for errors
- Verify backend is receiving requests
- Check AWS credentials and permissions

### Common Issues

1. **CORS Errors**: Backend is configured to allow all origins in development. For production, configure CORS properly.

2. **AWS Credentials**: Make sure AWS credentials are configured. The backend needs credentials to call Lex V2.

3. **Bot Not Responding**: 
   - Verify Bot ID and Alias ID
   - Check that the bot is published
   - Ensure Lambda functions are working
   - Check CloudWatch logs

## 🚀 Production Deployment

### Backend

1. Use environment variables for all configuration
2. Set up proper CORS for your domain
3. Use HTTPS
4. Implement rate limiting
5. Add authentication/authorization
6. Use process manager (PM2, systemd, etc.)
7. Set up logging and monitoring

### Frontend

1. Build for production:
   ```bash
   cd angular-ui
   npm run build
   ```

2. Deploy `dist/chatbot-ui` to your web server (Nginx, Apache, S3, etc.)

3. Update API URL in `chat.service.ts` to point to production backend

4. Configure CORS on backend for your domain

## 📚 Additional Resources

- [Angular Documentation](https://angular.io/docs)
- [AWS Lex V2 Documentation](https://docs.aws.amazon.com/lexv2/)
- [AWS SDK for JavaScript](https://docs.aws.amazon.com/sdk-for-javascript/)

## 🔐 Security Notes

- **Never commit AWS credentials** to version control
- Use IAM roles when possible
- Implement proper authentication for production
- Use HTTPS in production
- Validate and sanitize all inputs
- Keep dependencies updated

## 📝 License

MIT
