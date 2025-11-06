# Realtime & Notifications Implementation

## Overview

Complete implementation of Supabase Realtime for job status updates and notification system with expiry reminders, push/SMS stubs, and feature flags.

## Implementation Status

✅ **All tasks completed**

---

## 1. Realtime Channels

### Database Setup

**Migration**: `012_realtime_setup.sql`

**Enabled Tables**:
- `offers` - Job status updates
- `offer_assignments` - Job assignments
- `notifications` - In-app notifications

**Usage**:
```dart
// Subscribe to job status updates
final realtimeService = ref.watch(realtimeServiceProvider);
realtimeService.subscribeToOffers(
  onInsert: (data) => print('New job: $data'),
  onUpdate: (data) => print('Job updated: $data'),
  onDelete: (data) => print('Job deleted: $data'),
);
```

### Flutter Integration

**Location**: `lib/shared/services/realtime_service.dart`

**Features**:
- ✅ Subscribe to offers table changes
- ✅ Subscribe to offer_assignments table changes
- ✅ Subscribe to notifications table changes
- ✅ Subscribe to specific offer updates
- ✅ Auto-cleanup on dispose

**Example Usage**:
```dart
// Watch job status updates
final jobUpdates = ref.watch(jobStatusUpdatesProvider);

jobUpdates.whenData((update) {
  if (update['event'] == 'update') {
    final job = update['data'];
    // Handle job status change
  }
});

// Watch notifications
final notifications = ref.watch(
  notificationsStreamProvider(userId),
);

notifications.whenData((notification) {
  if (notification['event'] == 'insert') {
    // Show new notification
  }
});
```

---

## 2. Document Expiry Reminders

### SQL Functions

**Migration**: `013_document_expiry_reminders.sql`

**Functions**:
1. `send_document_expiry_reminders()` - Checks for expiring documents
   - 14 days before expiry
   - 3 days before expiry
   - Post-expiry notices

2. `process_document_expiry_demotions()` - Sends demotion notices
   - Triggered when verification_status is demoted
   - Notifies users about status changes

**Reminder Logic**:
- Checks documents expiring in 14 days
- Checks documents expiring in 3 days
- Checks expired documents (up to 1 day ago)
- Prevents duplicate reminders (unique constraint)

### Edge Function

**Location**: `supabase/functions/api-notifications-expiry-reminders/index.ts`

**Functionality**:
- Calls `send_document_expiry_reminders()` SQL function
- Processes pending notifications
- Sends notifications via notification service
- Handles demotion notices

**Usage**:
```bash
# Call via cron job or scheduler
curl -X POST https://your-project.supabase.co/functions/v1/api-notifications-expiry-reminders \
  -H "Authorization: Bearer <service_role_key>"
```

**Response**:
```json
{
  "success": true,
  "reminders_checked": 10,
  "reminders_sent": 5,
  "notifications_processed": 5,
  "demotion_notices": 2,
  "results": [...]
}
```

---

## 3. Notification Service

### Database Schema

**Migration**: `011_notifications_table.sql`

**Tables**:
- `notifications` - All notifications sent
- `user_notification_preferences` - User preferences
- `user_device_tokens` - FCM device tokens
- `user_phone_numbers` - SMS phone numbers
- `document_expiry_reminders` - Expiry reminder tracking

**Notification Types**:
- `job_status` - Job status changes
- `document_expiry` - Document expiring soon
- `document_expired` - Document expired
- `job_assigned` - Job assigned to professional
- `job_completed` - Job completed
- `payment_received` - Payment received
- `system` - System notifications

**Channels**:
- `in_app` - In-app notifications (always enabled)
- `push` - Push notifications (FCM)
- `sms` - SMS notifications (Twilio)
- `email` - Email notifications

### Notification Service

**Location**: `supabase/functions/_shared/notification_service.ts`

**Features**:
- ✅ Feature flags for channels (ENABLE_PUSH_NOTIFICATIONS, ENABLE_SMS_NOTIFICATIONS, ENABLE_EMAIL_NOTIFICATIONS)
- ✅ User preference checking
- ✅ Push notification stub (FCM)
- ✅ SMS notification stub (Twilio)
- ✅ Email notification stub
- ✅ In-app notification creation
- ✅ Multi-channel support

**Feature Flags**:
```bash
# Environment variables
ENABLE_PUSH_NOTIFICATIONS=true
ENABLE_SMS_NOTIFICATIONS=false
ENABLE_EMAIL_NOTIFICATIONS=true
```

**Push Notification Stub**:
```typescript
// Logs notification (stub)
console.log('[PUSH STUB] Sending push notification:', {
  userId, tokens, title, body, data
});

// In production, would call FCM API:
// POST https://fcm.googleapis.com/fcm/send
```

**SMS Notification Stub**:
```typescript
// Logs notification (stub)
console.log('[SMS STUB] Sending SMS notification:', {
  userId, phoneNumber, body
});

// In production, would call Twilio API:
// POST https://api.twilio.com/2010-04-01/Accounts/{accountSid}/Messages.json
```

### Send Notification Edge Function

**Location**: `supabase/functions/api-notifications-send/index.ts`

**Usage**:
```bash
curl -X POST https://your-project.supabase.co/functions/v1/api-notifications-send \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "uuid",
    "type": "job_status",
    "title": "Job Updated",
    "body": "Your job status has changed",
    "data": {"job_id": "uuid"},
    "channels": ["in_app", "push"]
  }'
```

---

## 4. Row Level Security

**Migration**: `014_notifications_rls.sql`

**Policies**:
- Users can view/update their own notifications
- Users can manage their own preferences
- Users can manage their own device tokens
- Users can manage their own phone numbers
- Admins can view all notifications

---

## 5. Cron Jobs & Scheduling

### Daily Expiry Reminders

**Recommended**: Run daily at 2 AM

```sql
-- Using pg_cron (if enabled)
SELECT cron.schedule(
  'document-expiry-reminders',
  '0 2 * * *', -- 2 AM daily
  $$
  SELECT send_document_expiry_reminders();
  $$
);
```

**Or via Edge Function**:
```bash
# Set up cron job to call:
# POST /api-notifications-expiry-reminders
```

### Document Expiry Processing

**Recommended**: Run daily at 3 AM (after reminders)

```sql
SELECT cron.schedule(
  'expire-documents',
  '0 3 * * *', -- 3 AM daily
  $$
  SELECT expire_pro_documents();
  SELECT process_document_expiry_demotions();
  $$
);
```

---

## Testing

### Manual Testing

1. **Test Realtime Updates**:
   ```dart
   // In Flutter app
   final realtimeService = ref.watch(realtimeServiceProvider);
   realtimeService.subscribeToOffers(
     onUpdate: (data) => print('Job updated: $data'),
   );
   
   // Update job status in database
   // Should see update in Flutter console
   ```

2. **Test Expiry Reminders**:
   ```bash
   # Create document expiring in 14 days
   # Call expiry reminders function
   curl -X POST https://your-project.supabase.co/functions/v1/api-notifications-expiry-reminders
   
   # Check notifications table
   # Should see reminder notifications
   ```

3. **Test Notification Sending**:
   ```bash
   # Send test notification
   curl -X POST https://your-project.supabase.co/functions/v1/api-notifications-send \
     -H "Authorization: Bearer <token>" \
     -d '{"user_id": "uuid", "type": "system", "title": "Test", "body": "Test notification"}'
   
   # Check logs for stub output
   # [PUSH STUB] Sending push notification: ...
   # [SMS STUB] Sending SMS notification: ...
   ```

### Test Scenarios

✅ Job status changes appear live in app
✅ Document expiry reminders fire (14d, 3d, expired)
✅ Demotion notices sent after expiry
✅ Notifications respect user preferences
✅ Feature flags disable/enable channels
✅ Push/SMS stubs log correctly

---

## Environment Variables

**Required**:
- `ENABLE_PUSH_NOTIFICATIONS` - Enable push notifications (true/false)
- `ENABLE_SMS_NOTIFICATIONS` - Enable SMS notifications (true/false)
- `ENABLE_EMAIL_NOTIFICATIONS` - Enable email notifications (true/false)

**Optional (for production)**:
- `FCM_API_KEY` - Firebase Cloud Messaging API key
- `TWILIO_ACCOUNT_SID` - Twilio account SID
- `TWILIO_AUTH_TOKEN` - Twilio auth token
- `TWILIO_PHONE_NUMBER` - Twilio phone number

---

## Deployment

### Deploy Migrations

```bash
supabase migration up
```

### Deploy Functions

```bash
supabase functions deploy api-notifications-send
supabase functions deploy api-notifications-expiry-reminders
```

### Enable Realtime

Realtime is enabled automatically via migration. Verify in Supabase Dashboard:
1. Go to Database → Replication
2. Ensure `offers`, `offer_assignments`, `notifications` are enabled

---

## Acceptance Criteria ✅

- [x] Supabase Realtime wired for job status/channel
- [x] Pre-expiry reminders (14d, 3d) implemented
- [x] Post-expiry demotion notices implemented
- [x] Push/SMS stubs with feature flags
- [x] Status changes appear live in app (via Flutter service)
- [x] Reminders fire in logs (stubs log correctly)

---

## Next Steps (Production)

1. **Implement FCM Integration**:
   - Replace push stub with FCM API calls
   - Handle device token registration
   - Handle notification delivery tracking

2. **Implement Twilio Integration**:
   - Replace SMS stub with Twilio API calls
   - Handle phone number verification
   - Handle SMS delivery tracking

3. **Implement Email Service**:
   - Integrate with SendGrid/SES
   - Handle email templates
   - Handle email delivery tracking

4. **Add Notification Preferences UI**:
   - Allow users to manage preferences
   - Device token registration UI
   - Phone number verification UI

---

## Related Documentation

- [Supabase Realtime](https://supabase.com/docs/guides/realtime)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Twilio SMS API](https://www.twilio.com/docs/sms)

