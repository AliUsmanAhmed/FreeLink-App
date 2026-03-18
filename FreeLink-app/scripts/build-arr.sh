#!/bin/bash
# scripts/build-aar.sh

echo "🏗️ Building Go AAR for FreeLink"

cd "$(dirname "$0")/../go"

# Initialize Go module
go mod init freelink-go
go mod tidy

# Install gomobile (only once per machine)
echo "📦 Installing gomobile..."
go install golang.org/x/mobile/cmd/gomobile@latest
go install golang.org/x/mobile/cmd/gobind@latest

# Setup gomobile (if not already done)
if [ ! -d "$HOME/gomobile" ]; then
  echo "🔧 Initializing gomobile..."
  gomobile init
fi

# Build the AAR for Android
echo "🔨 Building AAR..."
gomobile bind -target=android -o ../flutter/android/app/libs/freelink.aar .

echo "✅ AAR successfully built at ../flutter/android/app/libs/freelink.aar"
