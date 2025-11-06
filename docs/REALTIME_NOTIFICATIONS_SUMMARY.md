# Realtime & Notifications - Implementation Summary

## ✅ All Tasks Completed

### 1. Supabase Realtime for Job Status/Channel

**Status**: ✅ Implemented

**Database**:
- Migration `012_realtime_setup.sql` enables Realtime for:
  - `offers` table (job status updates)
  - `offer_assignments` table (job assignments)
  - `notifications` table (in-app notifications)

**Flutter Service**:
- `lib/shared/services/realtime_service.dart` provides:
  - `subscribeToOffers()` - Job status updates
  - `subscribeToAssignments()` - Job assignments
  - `subscribeToNotifications()` - In-app notifications
  - `subscribeToOffer()` - Specific job tracking
  - Auto-cleanup on dispose

**Usage**:
```dart
// Subscribe to job updates
final realtimeService = ref.watch(realtimeServiceProvider);
realtimeService.subscribeToOffers(
  onUpdate: (data) => {
    // Handle job status change in real-time
  }
);
```

---

### 2. Document Expiry Reminders

**Status**: ✅ Implemented

**SQL Functions** (`013_document_expiry_reminders.sql`):
- `send_document_expiry_reminders()` - Checks for:
  - Documents expiring in 14 days
  - Documents expiring in 3 days
  - Documents already expired
- `process_document_expiry_demotions()` - Sends demotion notices

**Edge Function**:
- `api-notifications-expiry-reminders` - Processes reminders and sends notifications

**Integration**:
- `expire_pro_documents()` updated to call `process_document_expiry_demotions()` after expiry

**Reminder Schedule**:
- 14 days before expiry → Reminder notification
- 3 days before expiry → Urgent reminder notification
- Post-expiry → Demotion notice when verification_status changes

---

### 3. Push/SMS Stubs with Feature Flags

**Status**: ✅ Implemented

**Notification Service** (`_shared/notification_service.ts`):
- Feature flags:
  - `ENABLE_PUSH_NOTIFICATIONS` - Enable push (FCM stub)
  - `ENABLE_SMS_NOTIFICATIONS` - Enable SMS (Twilio stub)
  - `ENABLE_EMAIL_NOTIFICATIONS` - Enable email (stub)
- User preference checking
- Multi-channel support

**Stubs**:
- **Push (FCM)**: Logs notification, ready for FCM API integration
- **SMS (Twilio)**: Logs notification, ready for Twilio API integration
- **Email**: Logs notification, ready for email service integration

**Logging**:
- All stub notifications log to console:
  - `[PUSH STUB] Sending push notification: ...`
  - `[SMS STUB] Sending SMS notification: ...`
  - `[EMAIL STUB] Sending email notification: ...`

---

## Database Schema

### New Tables

1. **notifications** - All notifications sent
   - Tracks type, channel, status, external_id
   - Supports in_app, push, sms, email

2. **user_notification_preferences** - User preferences
   - Channel preferences (push, sms, email)
   - Type preferences (job_status, document_reminders)

3. **user_device_tokens** - FCM device tokens
   - Stores device tokens for push notifications

4. **user_phone_numbers** - SMS phone numbers
   - Stores verified phone numbers for SMS

5. **document_expiry_reminders** - Reminder tracking
   - Prevents duplicate reminders
   - Tracks 14d, 3d, expired reminders

---

## Edge Functions

### 1. api-notifications-send

**Purpose**: Send notification to user

**Endpoint**: `POST /api-notifications-send`

**Request**:
```json
{
  "user_id": "uuid",
  "type": "job_status",
  "title": "Job Updated",
  "body": "Your job status has changed",
  "data": {"job_id": "uuid"},
  "channels": ["in_app", "push"]
}
```

**Response**:
```json
{
  "success": true,
  "results": [
    {"success": true, "channel": "in_app", "external_id": "..."},
    {"success": true, "channel": "push", "external_id": "..."}
  ]
}
```

### 2. api-notifications-expiry-reminders

**Purpose**: Process document expiry reminders

**Endpoint**: `POST /api-notifications-expiry-reminders`

**Response**:
```json
{
  "success": true,
  "reminders_checked": 10,
  "reminders_sent": 5,
  "notifications_processed": 5,
  "demotion_notices": 2
}
```

---

## Flutter Integration

### Realtime Service

**Location**: `lib/shared/services/realtime_service.dart`

**Providers**:
- `realtimeServiceProvider` - Realtime service instance
- `jobStatusUpdatesProvider` - Stream of job status updates
- `notificationsStreamProvider` - Stream of notifications (by userId)

**Example**:
```dart
// Watch job updates
final jobUpdates = ref.watch(jobStatusUpdatesProvider);

jobUpdates.whenData((update) {
  if (update['event'] == 'update') {
    final job = update['data'];
    // Update UI with new job status
  }
});
```

---

## Testing

### Manual Testing

1. **Test Realtime**:
   ```dart
   // Subscribe in Flutter app
   // Update job in database
   // Verify update appears in app
   ```

2. **Test Expiry Reminders**:
   ```bash
   # Create document expiring in 14 days
   # Call expiry reminders function
   curl -X POST /api-notifications-expiry-reminders
   # Check notifications table
   ```

3. **Test Notification Stubs**:
   ```bash
   # Send notification
   curl -X POST /api-notifications-send
   # Check logs for stub output
   ```

---

## Acceptance Criteria ✅

- [x] Supabase Realtime wired for job status/channel
- [x] Pre-expiry reminders (14d, 3d) implemented
- [x] Post-expiry demotion notices implemented
- [x] Push/SMS stubs with feature flags
- [x] Status changes appear live in app
- [x] Reminders fire in logs (stubs log correctly)

---

## Next Steps

1. **Production Push Integration**:
   - Replace FCM stub with actual FCM API calls
   - Add device token registration endpoint
   - Add delivery tracking

2. **Production SMS Integration**:
   - Replace Twilio stub with actual Twilio API calls
   - Add phone number verification flow
   - Add SMS delivery tracking

3. **Production Email Integration**:
   - Integrate with SendGrid/SES
   - Add email templates
   - Add email delivery tracking

4. **UI Enhancements**:
   - Notification preferences UI
   - Device token registration UI
   - Phone number verification UI
   - Notification center UI

---

## Files Created

### Migrations
- `011_notifications_table.sql` - Notifications schema
- `012_realtime_setup.sql` - Realtime configuration
- `013_document_expiry_reminders.sql` - Expiry reminder functions
- `014_notifications_rls.sql` - RLS policies

### Edge Functions
- `_shared/notification_service.ts` - Notification service
- `api-notifications-send/index.ts` - Send notifications
- `api-notifications-expiry-reminders/index.ts` - Process expiry reminders

### Flutter
- `lib/shared/services/realtime_service.dart` - Realtime service

### Documentation
- `docs/REALTIME_NOTIFICATIONS.md` - Complete documentation
- `docs/REALTIME_NOTIFICATIONS_SUMMARY.md` - This summary

---

## Environment Variables

```bash
# Feature flags
ENABLE_PUSH_NOTIFICATIONS=true
ENABLE_SMS_NOTIFICATIONS=false
ENABLE_EMAIL_NOTIFICATIONS=true

# Production (optional)
FCM_API_KEY=your_fcm_key
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=your_phone_number
```

---

## Deployment

```bash
# Deploy migrations
supabase migration up

# Deploy functions
supabase functions deploy api-notifications-send
supabase functions deploy api-notifications-expiry-reminders

# Set up cron jobs (optional)
# Daily at 2 AM: Call api-notifications-expiry-reminders
# Daily at 3 AM: Call expire_pro_documents()
```

