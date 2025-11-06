-- Enable RLS on notifications tables
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_phone_numbers ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_expiry_reminders ENABLE ROW LEVEL SECURITY;

-- Notifications policies
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
CREATE POLICY "Users can view their own notifications"
    ON notifications FOR SELECT
    USING (user_id = auth_user_id());

DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
CREATE POLICY "Users can update their own notifications"
    ON notifications FOR UPDATE
    USING (user_id = auth_user_id());

DROP POLICY IF EXISTS "Admins can view all notifications" ON notifications;
CREATE POLICY "Admins can view all notifications"
    ON notifications FOR SELECT
    USING (is_admin(auth_user_id()));

-- User notification preferences policies
DROP POLICY IF EXISTS "Users can view their own preferences" ON user_notification_preferences;
CREATE POLICY "Users can view their own preferences"
    ON user_notification_preferences FOR SELECT
    USING (user_id = auth_user_id());

DROP POLICY IF EXISTS "Users can update their own preferences" ON user_notification_preferences;
CREATE POLICY "Users can update their own preferences"
    ON user_notification_preferences FOR UPDATE
    USING (user_id = auth_user_id());

DROP POLICY IF EXISTS "Users can insert their own preferences" ON user_notification_preferences;
CREATE POLICY "Users can insert their own preferences"
    ON user_notification_preferences FOR INSERT
    WITH CHECK (user_id = auth_user_id());

-- User device tokens policies
DROP POLICY IF EXISTS "Users can manage their own device tokens" ON user_device_tokens;
CREATE POLICY "Users can manage their own device tokens"
    ON user_device_tokens FOR ALL
    USING (user_id = auth_user_id());

-- User phone numbers policies
DROP POLICY IF EXISTS "Users can manage their own phone numbers" ON user_phone_numbers;
CREATE POLICY "Users can manage their own phone numbers"
    ON user_phone_numbers FOR ALL
    USING (user_id = auth_user_id());

-- Document expiry reminders policies
DROP POLICY IF EXISTS "Users can view their own reminders" ON document_expiry_reminders;
CREATE POLICY "Users can view their own reminders"
    ON document_expiry_reminders FOR SELECT
    USING (user_id = auth_user_id());

DROP POLICY IF EXISTS "Admins can view all reminders" ON document_expiry_reminders;
CREATE POLICY "Admins can view all reminders"
    ON document_expiry_reminders FOR SELECT
    USING (is_admin(auth_user_id()));

