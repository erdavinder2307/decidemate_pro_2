#!/bin/bash

# DecideMate Pro Environment Setup Script
# This script helps team members set up their local environment

echo "🚀 DecideMate Pro Environment Setup"
echo "=================================="

# Check if .env.example exists
if [ ! -f ".env.example" ]; then
    echo "❌ Error: .env.example file not found!"
    echo "Make sure you're running this script from the project root directory."
    exit 1
fi

# Check if .env already exists
if [ -f ".env" ]; then
    echo "⚠️  .env file already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

# Copy .env.example to .env
cp .env.example .env
echo "✅ Created .env file from .env.example"

echo ""
echo "📝 Next Steps:"
echo "1. Edit the .env file and replace placeholder values with your actual Firebase configuration"
echo "2. Get your Firebase configuration from: https://console.firebase.google.com"
echo "3. Go to Project Settings > General > Your Apps"
echo "4. Copy the configuration values for each platform"
echo ""
echo "🔧 Firebase Console Steps:"
echo "- Web: Copy Web API Key, App ID, and Measurement ID"
echo "- Android: Copy Android API Key and App ID"
echo "- iOS: Copy iOS API Key, App ID, and Bundle ID"
echo ""
echo "⚠️  Security Reminder:"
echo "- Never commit the .env file to version control"
echo "- Keep your API keys secure and rotate them regularly"
echo "- Use different Firebase projects for development and production"
echo ""
echo "🔍 After updating .env, run:"
echo "flutter pub get"
echo "flutter run"
echo ""
echo "✨ Setup complete! Edit your .env file with actual Firebase values."

# Open .env file in default editor (optional)
read -p "Do you want to open .env file for editing now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v code &> /dev/null; then
        code .env
    elif command -v nano &> /dev/null; then
        nano .env
    elif command -v vi &> /dev/null; then
        vi .env
    else
        echo "Please edit .env manually with your preferred editor"
    fi
fi
