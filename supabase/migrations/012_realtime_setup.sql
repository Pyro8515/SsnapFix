-- Enable Realtime for offers table (job status updates)
ALTER PUBLICATION supabase_realtime ADD TABLE offers;

-- Enable Realtime for offer_assignments table (job assignments)
ALTER PUBLICATION supabase_realtime ADD TABLE offer_assignments;

-- Enable Realtime for notifications table (in-app notifications)
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- Note: Realtime is enabled by default for tables in Supabase
-- This migration explicitly adds tables to the realtime publication
-- Users can subscribe to changes on these tables via Supabase Realtime client

