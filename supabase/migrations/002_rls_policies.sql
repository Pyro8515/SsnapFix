-- Enable Row Level Security on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE professional_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pro_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE pro_trade_compliance ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE offer_assignments ENABLE ROW LEVEL SECURITY;

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM admin_users WHERE admin_users.user_id = is_admin.user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to get user_id from auth.uid()
CREATE OR REPLACE FUNCTION auth_user_id()
RETURNS UUID AS $$
BEGIN
    RETURN (SELECT id FROM users WHERE auth_user_id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Users policies
CREATE POLICY "Users can view their own record"
    ON users FOR SELECT
    USING (auth_user_id = auth.uid());

CREATE POLICY "Users can update their own record"
    ON users FOR UPDATE
    USING (auth_user_id = auth.uid());

CREATE POLICY "Admins can view all users"
    ON users FOR SELECT
    USING (is_admin(auth_user_id()));

-- Professional profiles policies
CREATE POLICY "Users can view their own profile"
    ON professional_profiles FOR SELECT
    USING (user_id = auth_user_id());

CREATE POLICY "Users can update their own profile"
    ON professional_profiles FOR UPDATE
    USING (user_id = auth_user_id());

CREATE POLICY "Users can insert their own profile"
    ON professional_profiles FOR INSERT
    WITH CHECK (user_id = auth_user_id());

CREATE POLICY "Admins can view all profiles"
    ON professional_profiles FOR SELECT
    USING (is_admin(auth_user_id()));

-- Pro documents policies
CREATE POLICY "Users can view their own documents"
    ON pro_documents FOR SELECT
    USING (user_id = auth_user_id());

CREATE POLICY "Users can insert their own documents"
    ON pro_documents FOR INSERT
    WITH CHECK (user_id = auth_user_id());

CREATE POLICY "Users can update their own documents"
    ON pro_documents FOR UPDATE
    USING (user_id = auth_user_id());

CREATE POLICY "Admins can view all documents"
    ON pro_documents FOR SELECT
    USING (is_admin(auth_user_id()));

CREATE POLICY "Admins can update all documents"
    ON pro_documents FOR UPDATE
    USING (is_admin(auth_user_id()));

-- Trade compliance policies
CREATE POLICY "Users can view their own compliance"
    ON pro_trade_compliance FOR SELECT
    USING (user_id = auth_user_id());

CREATE POLICY "Admins can view all compliance"
    ON pro_trade_compliance FOR SELECT
    USING (is_admin(auth_user_id()));

-- Admin users policies (only admins can view)
CREATE POLICY "Admins can view admin list"
    ON admin_users FOR SELECT
    USING (is_admin(auth_user_id()));

-- Webhook events (admin only)
CREATE POLICY "Admins can view webhook events"
    ON webhook_events FOR SELECT
    USING (is_admin(auth_user_id()));

-- Offers policies (public read for authenticated users, write for customers/admins)
CREATE POLICY "Authenticated users can view offers"
    ON offers FOR SELECT
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "Customers can create offers"
    ON offers FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL AND
        (customer_user_id = auth_user_id() OR customer_user_id IS NULL)
    );

CREATE POLICY "Offer owners can update their offers"
    ON offers FOR UPDATE
    USING (customer_user_id = auth_user_id());

CREATE POLICY "Admins can manage all offers"
    ON offers FOR ALL
    USING (is_admin(auth_user_id()));

-- Offer assignments policies
CREATE POLICY "Users can view assignments for their offers"
    ON offer_assignments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM offers 
            WHERE offers.id = offer_assignments.offer_id 
            AND offers.customer_user_id = auth_user_id()
        )
    );

CREATE POLICY "Professionals can view their own assignments"
    ON offer_assignments FOR SELECT
    USING (professional_user_id = auth_user_id());

CREATE POLICY "Admins can view all assignments"
    ON offer_assignments FOR SELECT
    USING (is_admin(auth_user_id()));
