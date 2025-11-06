#!/bin/bash
# Auto-run script - Automatically selects device and runs Flutter app

set -e

echo "🚀 GetDone - Auto Run Script"
echo "================================"
echo ""

# Load .env
if [ -f .env ]; then
    echo "📦 Loading .env..."
    export $(cat .env | grep -v '^#' | grep -v '^$' | xargs)
    echo "✅ Environment loaded"
else
    echo "⚠️  .env file not found!"
    exit 1
fi

# Build dart-define flags
FLAGS="--dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY --dart-define=API_BASE_URL=$API_BASE_URL"

if [ ! -z "$MAPBOX_TOKEN" ]; then
    FLAGS="$FLAGS --dart-define=MAPBOX_TOKEN=$MAPBOX_TOKEN"
fi

echo ""
echo "📝 Environment variables configured"
echo "   SUPABASE_URL: ${SUPABASE_URL:0:50}..."
echo "   API_BASE_URL: ${API_BASE_URL:0:50}..."
echo ""

# Check for devices
echo "🔍 Checking available devices..."
DEVICES=$(flutter devices 2>/dev/null | grep -E "•|desktop" || echo "")

if [ -z "$DEVICES" ]; then
    echo "❌ No devices found. Please start an emulator or connect a device."
    exit 1
fi

echo "$DEVICES"
echo ""

# Auto-select device (prefer macOS, then first available)
# Use Python to parse JSON device list
DEVICE_ID=$(flutter devices --machine 2>/dev/null | python3 -c "
import sys, json
try:
    devices = json.load(sys.stdin)
    # Prefer macOS
    macos = next((d['id'] for d in devices if 'macos' in d.get('id', '')), None)
    if macos:
        print(macos)
    elif devices:
        print(devices[0]['id'])
    else:
        print('')
except:
    print('macos')
" 2>/dev/null || echo "macos")

if [ -z "$DEVICE_ID" ] || [ "$DEVICE_ID" = "" ]; then
    echo "📱 Running Flutter (will prompt for device)..."
    flutter run $FLAGS
else
    echo "📱 Auto-selected device: $DEVICE_ID"
    echo "🚀 Starting Flutter app..."
    echo ""
    flutter run -d "$DEVICE_ID" $FLAGS
fi

