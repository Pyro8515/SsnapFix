# Environment Variables Setup

## Quick Setup

1. **Copy the template**:
   ```bash
   cp .env.example .env
   ```

2. **Fill in your values** from your Supabase Dashboard and other services

3. **For Flutter**, you have two options:

---

## Option 1: Using --dart-define (Current Approach) ✅

Your current code uses `String.fromEnvironment`, which requires compile-time flags.

### Create .env file manually:
```bash
# Create .env file in project root
touch .env
```

Then add your values (see `.env.example` for template).

### Run with environment variables:
```bash
# Development
flutter run --dart-define=SUPABASE_URL=https://ijuoaptgmpelljabmeqn.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-key-here \
  --dart-define=API_BASE_URL=https://ijuoaptgmpelljabmeqn.supabase.co/functions/v1

# Or create a launch script
```

### Or use a script to load from .env:
```bash
# Create scripts/run.sh or scripts/run.bat
#!/bin/bash
source .env
flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=API_BASE_URL=$API_BASE_URL
```

---

## Option 2: Using flutter_dotenv (Runtime Loading) 🔄

For runtime .env file loading, use the `flutter_dotenv` package.

### 1. Add dependency:
```yaml
# pubspec.yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

### 2. Add .env to assets:
```yaml
# pubspec.yaml
flutter:
  assets:
    - .env
```

### 3. Update environment.dart:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  static String get supabaseUrl => dotenv.get('SUPABASE_URL');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY');
  static String get apiBaseUrl => dotenv.get('API_BASE_URL');
}
```

### 4. Load .env in main.dart:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: EnvironmentConfig.supabaseUrl,
    anonKey: EnvironmentConfig.supabaseAnonKey,
  );
  
  runApp(const ProviderScope(child: GetDoneApp()));
}
```

---

## Your Current Values (Copy to .env)

Create `.env` file manually with these values:

```env
# Supabase Configuration
SUPABASE_URL=https://ijuoaptgmpelljabmeqn.supabase.co
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY_HERE
SUPABASE_SERVICE_ROLE_KEY=YOUR_SUPABASE_SERVICE_ROLE_KEY_HERE

# API Base URL
API_BASE_URL=https://ijuoaptgmpelljabmeqn.supabase.co/functions/v1

# Stripe Configuration
STRIPE_SECRET_KEY=sk_test_YOUR_STRIPE_SECRET_KEY_HERE
STRIPE_WEBHOOK_SECRET=whsec_YOUR_STRIPE_WEBHOOK_SECRET_HERE
STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_STRIPE_PUBLISHABLE_KEY_HERE

# Stripe Return URLs
STRIPE_IDENTITY_RETURN_URL=https://your-app.com/identity-return
STRIPE_CONNECT_RETURN_URL=https://your-app.com/connect-return
STRIPE_CONNECT_REFRESH_URL=https://your-app.com/connect-refresh

# Twilio Configuration
TWILIO_ACCOUNT_SID=AC_YOUR_TWILIO_ACCOUNT_SID_HERE
TWILIO_AUTH_TOKEN=YOUR_TWILIO_AUTH_TOKEN_HERE
TWILIO_MESSAGING_SERVICE_SID=
TWILIO_PROXY_SERVICE_SID=

# Mapbox Configuration
MAPBOX_TOKEN=pk.eyJ1IjoicHlyby1jMTUiLCJhIjoiY21mMzQ5YmVlMDd4NTJrbjh6ZmMwamR6ayJ9.BkhMCSjtAKMWoTz-VVtWYQ

# Sentry Configuration (Optional)
SENTRY_DSN=
```

---

## Important Notes

1. **`.env` is in `.gitignore`** - Never commit your actual `.env` file
2. **`.env.example` is committed** - This is the template for other developers
3. **For Edge Functions** - Set these in Supabase Dashboard → Project Settings → Edge Functions
4. **For Flutter** - Use either `--dart-define` flags or `flutter_dotenv` package

---

## Supabase Edge Functions Environment Variables

Set these in Supabase Dashboard → **Project Settings** → **Edge Functions**:

- `SUPABASE_URL` (auto-set)
- `SUPABASE_ANON_KEY` (auto-set)
- `SUPABASE_SERVICE_ROLE_KEY`
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_IDENTITY_RETURN_URL`
- `STRIPE_CONNECT_RETURN_URL`
- `STRIPE_CONNECT_REFRESH_URL`
- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`

---

## Next Steps

1. **Create `.env` file** manually with your values
2. **Choose approach**:
   - Option 1: Keep using `--dart-define` (current)
   - Option 2: Switch to `flutter_dotenv` (runtime loading)
3. **Set Edge Functions env vars** in Supabase Dashboard
4. **Test** your app with the new configuration

