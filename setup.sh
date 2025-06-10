#!/bin/bash

echo "🍋 Welcome to Lemon - AI Travel Planning App Setup"
echo "================================================"
echo ""

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18.x or later."
    exit 1
fi

echo "✅ Node.js $(node --version) detected"

# Backend setup
echo ""
echo "📦 Setting up backend..."
cd backend

# Install dependencies
echo "Installing dependencies..."
npm install

# Check for .env file
if [ ! -f .env ]; then
    echo ""
    echo "⚠️  No .env file found. Creating from .env.example..."
    cp .env.example .env
    echo "❗ Please edit backend/.env and add your OpenAI API key"
fi

cd ..

echo ""
echo "✅ Backend setup complete!"
echo ""
echo "📱 iOS App Setup Instructions:"
echo "1. Open LemonApp/LemonApp.xcodeproj in Xcode"
echo "2. Update the API endpoint in LemonApp/Services/APIService.swift"
echo "3. Build and run the app (Cmd + R)"
echo ""
echo "🚀 To start the backend locally:"
echo "   cd backend && npm run dev"
echo ""
echo "📚 For more information, see README.md"
echo ""
echo "Happy traveling with Lemon! 🍋"