#!/bin/bash

# Chatbot UI Setup Script
# This script sets up both the Angular frontend and Node.js backend

set -e

echo "🚀 Setting up Chatbot UI..."
echo ""

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 14+ first."
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 14 ]; then
    echo "❌ Node.js version 14+ is required. Current version: $(node -v)"
    exit 1
fi

echo "✅ Node.js $(node -v) found"
echo ""

# Setup Backend
echo "📦 Setting up backend service..."
cd backend
if [ ! -d "node_modules" ]; then
    npm install
    echo "✅ Backend dependencies installed"
else
    echo "✅ Backend dependencies already installed"
fi

if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "✅ Created .env file (please configure AWS credentials)"
else
    echo "✅ .env file already exists"
fi

cd ..

# Setup Angular Frontend
echo ""
echo "📦 Setting up Angular frontend..."
cd angular-ui
if [ ! -d "node_modules" ]; then
    npm install
    echo "✅ Angular dependencies installed"
else
    echo "✅ Angular dependencies already installed"
fi

cd ..

echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Configure AWS credentials (see backend/README.md)"
echo "   2. Start backend: cd backend && npm start"
echo "   3. Start frontend: cd angular-ui && npm start"
echo "   4. Open http://localhost:4200 in your browser"
echo ""

