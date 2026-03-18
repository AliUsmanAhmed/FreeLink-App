#!/bin/bash
# scripts/build-aar.sh

echo "🏗️ Building Go AAR for FreeLink"

cd "$(dirname "$0")/../go" || { echo "❌ Failed to enter go/ dir"; exit 1; }

# Init mod only if missing
if [ ! -f go.mod ]; then
  echo "📦 Initializing Go module..."
  go mod init freelink-go
fi

go mod tidy

# Install gomobile
echo "🔧 Installing gomobile..."
go install golang.org/x/mobile/cmd/gomobile@latest || { echo "❌ Failed to install gomobile"; exit 1; }
go install golang.org/x/mobile/cmd/gobind@latest || { echo "❌ Failed to install gobind"; exit 1; }

# Setup only once
if [ ! -d "$HOME/gomobile" ]; then
  echo "🔧 Initializing gomobile SDK..."
  gomobile init || { echo "❌ gomobile init failed"; exit 1; }
fi

# Build AAR
echo "🔨 Building AAR..."
gomobile bind -target=android -o ../flutter/android/app/libs/freelink.aar . \
  || { echo "❌ AAR build failed"; exit 1; }

echo "✅ AAR built at ../flutter/android/app/libs/freelink.aar"
