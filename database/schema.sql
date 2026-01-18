-- ============================================
-- Newsletter Automation SaaS - Database Schema
-- For Supabase / PostgreSQL
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- CLIENTS (SaaS Customers)
-- ============================================
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    company_name TEXT NOT NULL,
    plan TEXT DEFAULT 'free' CHECK (plan IN ('free', 'starter', 'pro', 'enterprise')),
    api_key TEXT UNIQUE DEFAULT ('nla_' || substr(md5(random()::text), 1, 24)),

    -- Limits based on plan
    newsletters_limit INTEGER DEFAULT 1,
    emails_per_month INTEGER DEFAULT 500,

    -- Status
    is_active BOOLEAN DEFAULT true,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Plan limits reference:
-- free: 1 newsletter, 500 emails/month
-- starter: 3 newsletters, 2000 emails/month
-- pro: 10 newsletters, 10000 emails/month
-- enterprise: unlimited

-- ============================================
-- NEWSLETTERS (Per Client)
-- ============================================
CREATE TABLE newsletters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,

    -- Basic info
    name TEXT NOT NULL,
    industry TEXT,

    -- Scheduling
    is_active BOOLEAN DEFAULT true,
    schedule_enabled BOOLEAN DEFAULT true,
    schedule_hour INTEGER DEFAULT 7 CHECK (schedule_hour >= 0 AND schedule_hour <= 23),
    schedule_minute INTEGER DEFAULT 0 CHECK (schedule_minute >= 0 AND schedule_minute <= 59),
    schedule_timezone TEXT DEFAULT 'UTC',
    schedule_days INTEGER[] DEFAULT ARRAY[1,2,3,4,5], -- 0=Sun, 1=Mon, etc.

    -- AI Settings
    ai_summaries_enabled BOOLEAN DEFAULT true,
    max_articles INTEGER DEFAULT 12,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- NEWSLETTER BRANDING
-- ============================================
CREATE TABLE newsletter_branding (
    newsletter_id UUID PRIMARY KEY REFERENCES newsletters(id) ON DELETE CASCADE,

    title TEXT NOT NULL,
    subtitle TEXT,
    logo_url TEXT,

    -- Colors (hex)
    primary_color TEXT DEFAULT '#667eea',
    secondary_color TEXT DEFAULT '#764ba2',

    -- Footer
    footer_text TEXT,

    -- Social links (JSON)
    social_links JSONB DEFAULT '{}'::jsonb,

    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- NEWSLETTER SOURCES (RSS, NewsAPI, etc.)
-- ============================================
CREATE TABLE newsletter_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    newsletter_id UUID NOT NULL REFERENCES newsletters(id) ON DELETE CASCADE,

    source_type TEXT NOT NULL CHECK (source_type IN ('rss', 'newsapi', 'custom_api')),
    source_url TEXT,

    -- Keywords for NewsAPI
    keywords TEXT[],
    exclude_keywords TEXT[] DEFAULT ARRAY['sponsored', 'advertisement'],

    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- NEWSLETTER CATEGORIES (Custom per newsletter)
-- ============================================
CREATE TABLE newsletter_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    newsletter_id UUID NOT NULL REFERENCES newsletters(id) ON DELETE CASCADE,

    name TEXT NOT NULL,
    icon TEXT DEFAULT '📰',
    color TEXT DEFAULT '#6B7280',
    keywords TEXT[] DEFAULT ARRAY[]::TEXT[],

    sort_order INTEGER DEFAULT 0,

    UNIQUE(newsletter_id, name)
);

-- ============================================
-- NEWSLETTER RECIPIENTS (Subscribers)
-- ============================================
CREATE TABLE newsletter_recipients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    newsletter_id UUID NOT NULL REFERENCES newsletters(id) ON DELETE CASCADE,

    email TEXT NOT NULL,
    name TEXT,

    is_active BOOLEAN DEFAULT true,
    subscribed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    unsubscribed_at TIMESTAMP WITH TIME ZONE,

    -- Tracking
    opens_count INTEGER DEFAULT 0,
    last_opened_at TIMESTAMP WITH TIME ZONE,

    UNIQUE(newsletter_id, email)
);

-- ============================================
-- DELIVERY CHANNELS (Email, Telegram, Slack, etc.)
-- ============================================
CREATE TABLE newsletter_channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    newsletter_id UUID NOT NULL REFERENCES newsletters(id) ON DELETE CASCADE,

    channel_type TEXT NOT NULL CHECK (channel_type IN ('email', 'telegram', 'slack', 'discord', 'webhook')),
    is_enabled BOOLEAN DEFAULT true,

    -- Channel-specific config (JSON)
    config JSONB DEFAULT '{}'::jsonb,

    UNIQUE(newsletter_id, channel_type)
);

-- ============================================
-- DELIVERY LOGS (For analytics & billing)
-- ============================================
CREATE TABLE delivery_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    newsletter_id UUID NOT NULL REFERENCES newsletters(id) ON DELETE CASCADE,

    delivered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Trigger info
    trigger_type TEXT CHECK (trigger_type IN ('scheduled', 'manual', 'api', 'test')),

    -- Status
    status TEXT CHECK (status IN ('success', 'partial', 'failed')),
    error_message TEXT,

    -- Stats
    articles_count INTEGER DEFAULT 0,
    recipients_count INTEGER DEFAULT 0,
    channels_used TEXT[],
    execution_time_ms INTEGER,

    -- For debugging
    metadata JSONB DEFAULT '{}'::jsonb
);

-- ============================================
-- USAGE STATS (Monthly billing metrics)
-- ============================================
CREATE TABLE usage_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,

    month DATE NOT NULL, -- First day of month

    newsletters_sent INTEGER DEFAULT 0,
    emails_sent INTEGER DEFAULT 0,
    telegram_messages INTEGER DEFAULT 0,
    ai_tokens_used INTEGER DEFAULT 0,

    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(client_id, month)
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX idx_newsletters_client ON newsletters(client_id);
CREATE INDEX idx_newsletters_active_schedule ON newsletters(schedule_hour, schedule_minute)
    WHERE is_active = true AND schedule_enabled = true;
CREATE INDEX idx_sources_newsletter ON newsletter_sources(newsletter_id);
CREATE INDEX idx_categories_newsletter ON newsletter_categories(newsletter_id);
CREATE INDEX idx_recipients_newsletter ON newsletter_recipients(newsletter_id) WHERE is_active = true;
CREATE INDEX idx_channels_newsletter ON newsletter_channels(newsletter_id);
CREATE INDEX idx_logs_client_date ON delivery_logs(client_id, delivered_at DESC);
CREATE INDEX idx_logs_newsletter ON delivery_logs(newsletter_id, delivered_at DESC);
CREATE INDEX idx_usage_client_month ON usage_stats(client_id, month DESC);

-- ============================================
-- ROW LEVEL SECURITY (Multi-tenant isolation)
-- ============================================
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletters ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletter_branding ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletter_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletter_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletter_recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletter_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_stats ENABLE ROW LEVEL SECURITY;

-- Example RLS policy (adjust based on your auth setup)
-- CREATE POLICY "Users can only access their own data" ON newsletters
--     FOR ALL USING (client_id = auth.uid());

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to relevant tables
CREATE TRIGGER update_clients_timestamp BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_newsletters_timestamp BEFORE UPDATE ON newsletters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_branding_timestamp BEFORE UPDATE ON newsletter_branding
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Function to increment usage stats
CREATE OR REPLACE FUNCTION increment_usage(
    p_client_id UUID,
    p_newsletters INTEGER DEFAULT 0,
    p_emails INTEGER DEFAULT 0,
    p_telegram INTEGER DEFAULT 0,
    p_ai_tokens INTEGER DEFAULT 0
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO usage_stats (client_id, month, newsletters_sent, emails_sent, telegram_messages, ai_tokens_used)
    VALUES (p_client_id, DATE_TRUNC('month', NOW())::DATE, p_newsletters, p_emails, p_telegram, p_ai_tokens)
    ON CONFLICT (client_id, month) DO UPDATE SET
        newsletters_sent = usage_stats.newsletters_sent + p_newsletters,
        emails_sent = usage_stats.emails_sent + p_emails,
        telegram_messages = usage_stats.telegram_messages + p_telegram,
        ai_tokens_used = usage_stats.ai_tokens_used + p_ai_tokens,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- VIEWS
-- ============================================

-- View for newsletters due to be sent (for scheduled trigger)
CREATE VIEW newsletters_due AS
SELECT
    n.*,
    c.email as client_email,
    c.company_name,
    c.plan,
    c.is_active as client_active
FROM newsletters n
JOIN clients c ON n.client_id = c.id
WHERE n.is_active = true
    AND n.schedule_enabled = true
    AND c.is_active = true
    AND EXTRACT(DOW FROM NOW() AT TIME ZONE n.schedule_timezone) = ANY(n.schedule_days)
    AND EXTRACT(HOUR FROM NOW() AT TIME ZONE n.schedule_timezone) = n.schedule_hour
    AND EXTRACT(MINUTE FROM NOW() AT TIME ZONE n.schedule_timezone) >= n.schedule_minute
    AND EXTRACT(MINUTE FROM NOW() AT TIME ZONE n.schedule_timezone) < n.schedule_minute + 5;

-- View for client dashboard
CREATE VIEW client_dashboard AS
SELECT
    c.id,
    c.company_name,
    c.plan,
    c.newsletters_limit,
    c.emails_per_month,
    COUNT(DISTINCT n.id) as newsletters_count,
    COALESCE(SUM(us.emails_sent), 0) as emails_this_month,
    COALESCE(SUM(us.newsletters_sent), 0) as newsletters_this_month
FROM clients c
LEFT JOIN newsletters n ON n.client_id = c.id
LEFT JOIN usage_stats us ON us.client_id = c.id AND us.month = DATE_TRUNC('month', NOW())::DATE
GROUP BY c.id;
