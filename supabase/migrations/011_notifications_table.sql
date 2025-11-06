-- Notifications table for tracking all notifications sent to users
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('job_status', 'document_expiry', 'document_expired', 'job_assigned', 'job_completed', 'payment_received', 'system')),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB, -- Additional data for the notification (job_id, document_id, etc.)
    channel TEXT NOT NULL CHECK (channel IN ('push', 'sms', 'email', 'in_app')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'delivered', 'read')),
    external_id TEXT, -- External notification ID (from FCM, Twilio, etc.)
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_user_status ON notifications(user_id, status);

-- User notification preferences
CREATE TABLE IF NOT EXISTS user_notification_preferences (
    user_id UUID NOT NULL PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    push_enabled BOOLEAN NOT NULL DEFAULT true,
    sms_enabled BOOLEAN NOT NULL DEFAULT false,
    email_enabled BOOLEAN NOT NULL DEFAULT true,
    job_status_enabled BOOLEAN NOT NULL DEFAULT true,
    document_reminders_enabled BOOLEAN NOT NULL DEFAULT true,
    marketing_enabled BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- User device tokens for push notifications (FCM)
CREATE TABLE IF NOT EXISTS user_device_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_token TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
    app_version TEXT,
    device_info JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, device_token)
);

-- User phone numbers for SMS (Twilio)
CREATE TABLE IF NOT EXISTS user_phone_numbers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    phone_number TEXT NOT NULL,
    verified BOOLEAN NOT NULL DEFAULT false,
    verification_code TEXT,
    verification_expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, phone_number)
);

-- Document expiry reminders tracking
CREATE TABLE IF NOT EXISTS document_expiry_reminders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL REFERENCES pro_documents(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reminder_type TEXT NOT NULL CHECK (reminder_type IN ('14_days', '3_days', 'expired')),
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notification_id UUID REFERENCES notifications(id) ON DELETE SET NULL,
    UNIQUE(document_id, reminder_type)
);

-- Indexes for expiry reminders
CREATE INDEX IF NOT EXISTS idx_document_expiry_reminders_document_id ON document_expiry_reminders(document_id);
CREATE INDEX IF NOT EXISTS idx_document_expiry_reminders_user_id ON document_expiry_reminders(user_id);

-- Updated_at trigger for user_notification_preferences
DROP TRIGGER IF EXISTS update_user_notification_preferences_updated_at ON user_notification_preferences;
CREATE TRIGGER update_user_notification_preferences_updated_at BEFORE UPDATE ON user_notification_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

