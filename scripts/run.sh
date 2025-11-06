#!/bin/bash
# Script to run Flutter app with environment variables from .env file

set -e

# Load .env file if it exists
if [ -f .env ]; then
    echo "📦 Loading environment variables from .env..."
    export $(cat .env | grep -v '^#' | grep -v '^$' | xargs)
    echo "✅ Environment variables loaded"
else
    echo "⚠️  Warning: .env file not found. Using default values."
fi

# Build dart-define flags
DART_DEFINES=""

# Add SUPABASE_URL if set
if [ ! -z "$SUPABASE_URL" ]; then
    DART_DEFINES="$DART_DEFINES --dart-define=SUPABASE_URL=$SUPABASE_URL"
fi

# Add SUPABASE_ANON_KEY if set
if [ ! -z "$SUPABASE_ANON_KEY" ]; then
    DART_DEFINES="$DART_DEFINES --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
fi

# Add API_BASE_URL if set
if [ ! -z "$API_BASE_URL" ]; then
    DART_DEFINES="$DART_DEFINES --dart-define=API_BASE_URL=$API_BASE_URL"
fi

# Add MAPBOX_TOKEN if set
if [ ! -z "$MAPBOX_TOKEN" ]; then
    DART_DEFINES="$DART_DEFINES --dart-define=MAPBOX_TOKEN=$MAPBOX_TOKEN"
fi

echo "🚀 Running Flutter app..."
echo "📝 Using dart-define flags: $DART_DEFINES"
echo ""

# Auto-select device if available
# Prefer macOS (desktop) if available, otherwise use first available device
DEVICE=$(flutter devices --machine 2>/dev/null | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4 || echo "")

if [ ! -z "$DEVICE" ]; then
    echo "📱 Using device: $DEVICE"
    flutter run -d "$DEVICE" $DART_DEFINES
else
    echo "📱 No device specified, Flutter will prompt for device selection"
    flutter run $DART_DEFINES
fi

