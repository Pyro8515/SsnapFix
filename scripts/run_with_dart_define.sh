#!/bin/bash
# Script to run Flutter app with environment variables from .env file
# This loads .env and passes values as --dart-define flags

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

# Run Flutter
flutter run $DART_DEFINES

