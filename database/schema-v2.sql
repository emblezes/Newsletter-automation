-- ============================================
-- Newsletter SaaS V2 - Ultra-Personalized Schema
-- ============================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For text similarity

-- ============================================
-- COMPANIES (Entreprises clientes)
-- ============================================
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Authentification
    email TEXT UNIQUE NOT NULL,

    -- Profil entreprise
    name TEXT NOT NULL,
    industry TEXT NOT NULL,
    industry_subcategory TEXT,
    company_size TEXT CHECK (company_size IN ('1-10', '11-50', '51-200', '201-1000', '1000+')),

    -- Description pour l'IA
    description TEXT,  -- "Nous developpons une plateforme SaaS B2B..."
    products_services TEXT[],  -- ['Gestion projet', 'Automatisation', 'Analytics']
    target_market TEXT,  -- "PME europeennes"
    geographic_focus TEXT[],  -- ['France', 'Europe']

    -- Concurrents detectes/ajoutes
    competitors TEXT[],  -- ['Asana', 'Monday.com', 'Notion']

    -- Plan & Billing
    plan TEXT DEFAULT 'free' CHECK (plan IN ('free', 'starter', 'pro', 'enterprise')),
    api_key TEXT UNIQUE DEFAULT ('nla_' || substr(md5(random()::text), 1, 24)),

    -- Limites
    newsletters_limit INTEGER DEFAULT 1,
    emails_per_month INTEGER DEFAULT 500,
    team_members_limit INTEGER DEFAULT 3,

    -- Branding global (herite par les newsletters)
    logo_url TEXT,
    primary_color TEXT DEFAULT '#667eea',
    secondary_color TEXT DEFAULT '#764ba2',

    -- Status
    is_active BOOLEAN DEFAULT true,
    onboarding_completed BOOLEAN DEFAULT false,
    onboarding_step INTEGER DEFAULT 1,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- COMPANY_INTERESTS (Centres d'interet)
-- ============================================
CREATE TABLE company_interests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

    -- Interet
    topic TEXT NOT NULL,  -- 'Intelligence Artificielle'
    category TEXT,  -- 'technology', 'business', 'industry'

    -- Source
    source TEXT CHECK (source IN ('ai_suggested', 'user_selected', 'onboarding', 'feedback')),
    confidence_score FLOAT DEFAULT 1.0,  -- 0.0 to 1.0

    -- Status
    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(company_id, topic)
);

-- ============================================
-- COMPANY_KEYWORDS (Mots-cles personnalises)
-- ============================================
CREATE TABLE company_keywords (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

    keyword TEXT NOT NULL,
    keyword_type TEXT CHECK (keyword_type IN ('include', 'exclude', 'competitor', 'product', 'brand')),

    -- Poids pour le scoring
    weight FLOAT DEFAULT 1.0,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(company_id, keyword, keyword_type)
);

-- ============================================
-- TEAM_MEMBERS (Membres de l'equipe)
-- ============================================
CREATE TABLE team_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

    email TEXT NOT NULL,
    name TEXT,
    role TEXT,  -- 'CEO', 'CTO', 'Marketing Manager'
    department TEXT,  -- 'Direction', 'Tech', 'Marketing', 'Sales', 'Product'

    -- Permissions
    is_admin BOOLEAN DEFAULT false,
    can_create_newsletters BOOLEAN DEFAULT true,
    can_manage_team BOOLEAN DEFAULT false,

    -- Preferences individuelles
    preferred_language TEXT DEFAULT 'fr',
    timezone TEXT DEFAULT 'Europe/Paris',

    -- Status
    is_active BOOLEAN DEFAULT true,
    invited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    joined_at TIMESTAMP WITH TIME ZONE,

    UNIQUE(company_id, email)
);

-- ============================================
-- NEWSLETTERS (V2 - Enhanced)
-- ============================================
CREATE TABLE newsletters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

    -- Identite
    name TEXT NOT NULL,  -- Nom interne: "Direction & Strategie"
    display_title TEXT,  -- Titre affiche: "TechStartup - Veille Strategique"
    subtitle TEXT,  -- "L'essentiel pour les decideurs"

    -- Ciblage
    target_department TEXT,  -- 'Direction', 'Tech', 'Marketing', etc.
    target_roles TEXT[],  -- ['CEO', 'CTO', 'VP']

    -- Configuration contenu
    max_articles INTEGER DEFAULT 12,
    min_articles INTEGER DEFAULT 3,  -- Ne pas envoyer si moins de X articles

    -- AI Settings
    ai_enabled BOOLEAN DEFAULT true,
    ai_summary_style TEXT DEFAULT 'concise',  -- 'concise', 'detailed', 'bullet_points'
    ai_tone TEXT DEFAULT 'professional',  -- 'professional', 'casual', 'technical'
    ai_language TEXT DEFAULT 'fr',

    -- Planification
    is_active BOOLEAN DEFAULT true,
    schedule_enabled BOOLEAN DEFAULT true,
    schedule_hour INTEGER DEFAULT 7,
    schedule_minute INTEGER DEFAULT 30,
    schedule_timezone TEXT DEFAULT 'Europe/Paris',
    schedule_days INTEGER[] DEFAULT ARRAY[1,2,3,4,5],

    -- Branding (override company defaults)
    custom_logo_url TEXT,
    custom_primary_color TEXT,
    custom_secondary_color TEXT,
    footer_text TEXT,

    -- Stats
    total_sent INTEGER DEFAULT 0,
    avg_open_rate FLOAT,
    avg_click_rate FLOAT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_sent_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- NEWSLETTER_TOPICS (Sujets par newsletter)
-- ============================================
CREATE TABLE newsletter_topics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    newsletter_id UUID NOT NULL REFERENCES newsletters(id) ON DELETE CASCADE,

    -- Topic info
    topic TEXT NOT NULL,
    display_name TEXT,  -- Nom affiche si different
    icon TEXT DEFAULT '📰',
    color TEXT DEFAULT '#6B7280',

    -- Keywords pour l'IA
    keywords TEXT[],
    exclude_keywords TEXT[],

    -- Importance
    priority INTEGER DEFAULT 0,  -- Ordre d'affichage
    min_articles INTEGER DEFAULT 0,  -- Minimum d'articles de ce topic
    max_articles INTEGER,  -- Maximum d'articles

    is_active BOOLEAN DEFAULT true,

    UNIQUE(newsletter_id, topic)
);

-- ============================================
-- NEWSLETTER_SOURCES (Sources par newsletter)
-- ============================================
CREATE TABLE newsletter_sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    newsletter_id UUID NOT NULL REFERENCES newsletters(id) ON DELETE CASCADE,

    source_type TEXT NOT NULL CHECK (source_type IN ('rss', 'newsapi', 'twitter', 'reddit', 'custom')),
    source_url TEXT,
    source_name TEXT,

    -- Pour NewsAPI
    keywords TEXT[],
    domains TEXT[],  -- Domaines specifiques
    exclude_domains TEXT[],

    -- Qualite
    trust_score FLOAT DEFAULT 1.0,  -- Score de confiance de la source

    is_active BOOLEAN DEFAULT true,
    last_fetched_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- NEWSLETTER_RECIPIENTS (Abonnes)
-- ============================================
CREATE TABLE newsletter_recipients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    newsletter_id UUID NOT NULL REFERENCES newsletters(id) ON DELETE CASCADE,
    team_member_id UUID REFERENCES team_members(id) ON DELETE SET NULL,

    -- Contact
    email TEXT NOT NULL,
    name TEXT,

    -- Preferences individuelles
    preferred_format TEXT DEFAULT 'html',  -- 'html', 'text', 'digest'

    -- Status
    is_active BOOLEAN DEFAULT true,
    subscribed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    unsubscribed_at TIMESTAMP WITH TIME ZONE,
    unsubscribe_reason TEXT,

    -- Engagement
    emails_received INTEGER DEFAULT 0,
    emails_opened INTEGER DEFAULT 0,
    links_clicked INTEGER DEFAULT 0,
    last_opened_at TIMESTAMP WITH TIME ZONE,
    last_clicked_at TIMESTAMP WITH TIME ZONE,

    UNIQUE(newsletter_id, email)
);

-- ============================================
-- NEWSLETTER_CHANNELS (Canaux de diffusion)
-- ============================================
CREATE TABLE newsletter_channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    newsletter_id UUID NOT NULL REFERENCES newsletters(id) ON DELETE CASCADE,

    channel_type TEXT NOT NULL CHECK (channel_type IN ('email', 'telegram', 'slack', 'discord', 'teams', 'webhook')),
    is_enabled BOOLEAN DEFAULT true,

    -- Config specifique au canal (JSON)
    config JSONB DEFAULT '{}'::jsonb,

    -- Stats par canal
    messages_sent INTEGER DEFAULT 0,
    last_sent_at TIMESTAMP WITH TIME ZONE,

    UNIQUE(newsletter_id, channel_type)
);

-- ============================================
-- ARTICLE_FEEDBACK (Feedback sur les articles)
-- ============================================
CREATE TABLE article_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    newsletter_id UUID REFERENCES newsletters(id) ON DELETE SET NULL,
    recipient_id UUID REFERENCES newsletter_recipients(id) ON DELETE SET NULL,

    -- Article info
    article_url TEXT NOT NULL,
    article_title TEXT,
    article_source TEXT,
    article_topic TEXT,

    -- Feedback
    feedback_type TEXT CHECK (feedback_type IN ('useful', 'not_relevant', 'block_topic', 'block_source')),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- DELIVERY_LOGS (Logs de livraison)
-- ============================================
CREATE TABLE delivery_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    newsletter_id UUID NOT NULL REFERENCES newsletters(id) ON DELETE CASCADE,

    -- Timing
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,

    -- Trigger
    trigger_type TEXT CHECK (trigger_type IN ('scheduled', 'manual', 'api', 'test')),
    triggered_by UUID REFERENCES team_members(id),

    -- Status
    status TEXT CHECK (status IN ('pending', 'processing', 'success', 'partial', 'failed', 'skipped')),
    skip_reason TEXT,  -- 'no_articles', 'limit_reached', etc.
    error_message TEXT,

    -- Metrics
    articles_found INTEGER DEFAULT 0,
    articles_sent INTEGER DEFAULT 0,
    recipients_count INTEGER DEFAULT 0,
    emails_sent INTEGER DEFAULT 0,
    emails_bounced INTEGER DEFAULT 0,

    -- Channels used
    channels_used TEXT[],

    -- Performance
    fetch_time_ms INTEGER,
    ai_time_ms INTEGER,
    send_time_ms INTEGER,
    total_time_ms INTEGER,

    -- Cost tracking
    ai_tokens_used INTEGER DEFAULT 0,

    -- Debug
    metadata JSONB DEFAULT '{}'::jsonb
);

-- ============================================
-- USAGE_STATS (Stats mensuelles)
-- ============================================
CREATE TABLE usage_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

    month DATE NOT NULL,

    -- Counts
    newsletters_sent INTEGER DEFAULT 0,
    emails_sent INTEGER DEFAULT 0,
    telegram_messages INTEGER DEFAULT 0,
    slack_messages INTEGER DEFAULT 0,

    -- AI
    ai_requests INTEGER DEFAULT 0,
    ai_tokens_used INTEGER DEFAULT 0,

    -- Engagement
    total_opens INTEGER DEFAULT 0,
    total_clicks INTEGER DEFAULT 0,

    -- Billing
    overage_emails INTEGER DEFAULT 0,

    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(company_id, month)
);

-- ============================================
-- AI_SUGGESTIONS (Suggestions IA)
-- ============================================
CREATE TABLE ai_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

    suggestion_type TEXT CHECK (suggestion_type IN ('topic', 'source', 'keyword', 'competitor', 'newsletter_template')),

    -- Suggestion content
    suggestion_data JSONB NOT NULL,
    -- Example: {"topic": "Product Management", "reason": "Based on your SaaS focus", "confidence": 0.85}

    -- Status
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'ignored')),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    responded_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- INDUSTRY_TEMPLATES (Templates par industrie)
-- ============================================
CREATE TABLE industry_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    industry TEXT NOT NULL,
    industry_subcategory TEXT,

    -- Suggested configuration
    suggested_topics JSONB,  -- [{"name": "AI & ML", "icon": "🤖", "keywords": [...]}]
    suggested_sources JSONB,  -- [{"type": "rss", "url": "...", "name": "TechCrunch"}]
    suggested_competitors JSONB,  -- ["Asana", "Monday.com"]
    suggested_keywords JSONB,  -- {"include": [...], "exclude": [...]}

    -- Newsletter templates
    newsletter_templates JSONB,  -- [{"name": "Direction", "topics": [...], "target": "leadership"}]

    -- Branding suggestions
    suggested_colors JSONB,  -- {"primary": "#667eea", "secondary": "#764ba2"}

    is_active BOOLEAN DEFAULT true,

    UNIQUE(industry, industry_subcategory)
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX idx_companies_industry ON companies(industry);
CREATE INDEX idx_companies_active ON companies(is_active) WHERE is_active = true;
CREATE INDEX idx_newsletters_company ON newsletters(company_id);
CREATE INDEX idx_newsletters_schedule ON newsletters(schedule_hour, schedule_minute) WHERE is_active = true AND schedule_enabled = true;
CREATE INDEX idx_recipients_newsletter ON newsletter_recipients(newsletter_id) WHERE is_active = true;
CREATE INDEX idx_feedback_company ON article_feedback(company_id);
CREATE INDEX idx_logs_company_date ON delivery_logs(company_id, started_at DESC);
CREATE INDEX idx_usage_company_month ON usage_stats(company_id, month DESC);
CREATE INDEX idx_interests_company ON company_interests(company_id) WHERE is_active = true;

-- Full text search on company description
CREATE INDEX idx_companies_description_fts ON companies USING gin(to_tsvector('french', description));

-- ============================================
-- FUNCTIONS
-- ============================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_companies_timestamp BEFORE UPDATE ON companies FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_newsletters_timestamp BEFORE UPDATE ON newsletters FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Generate AI suggestions based on company profile
CREATE OR REPLACE FUNCTION generate_ai_suggestions(p_company_id UUID)
RETURNS VOID AS $$
DECLARE
    v_company RECORD;
    v_template RECORD;
BEGIN
    -- Get company info
    SELECT * INTO v_company FROM companies WHERE id = p_company_id;

    -- Get industry template
    SELECT * INTO v_template FROM industry_templates
    WHERE industry = v_company.industry
    AND (industry_subcategory IS NULL OR industry_subcategory = v_company.industry_subcategory)
    LIMIT 1;

    IF v_template IS NOT NULL THEN
        -- Insert topic suggestions
        INSERT INTO ai_suggestions (company_id, suggestion_type, suggestion_data)
        SELECT
            p_company_id,
            'topic',
            jsonb_build_object('topic', t->>'name', 'icon', t->>'icon', 'keywords', t->'keywords', 'confidence', 0.8)
        FROM jsonb_array_elements(v_template.suggested_topics) AS t
        ON CONFLICT DO NOTHING;

        -- Insert source suggestions
        INSERT INTO ai_suggestions (company_id, suggestion_type, suggestion_data)
        SELECT
            p_company_id,
            'source',
            jsonb_build_object('type', s->>'type', 'url', s->>'url', 'name', s->>'name', 'confidence', 0.75)
        FROM jsonb_array_elements(v_template.suggested_sources) AS s
        ON CONFLICT DO NOTHING;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Calculate company engagement score
CREATE OR REPLACE FUNCTION get_company_engagement_score(p_company_id UUID)
RETURNS FLOAT AS $$
DECLARE
    v_score FLOAT;
BEGIN
    SELECT
        COALESCE(
            (SUM(nr.emails_opened)::FLOAT / NULLIF(SUM(nr.emails_received), 0)) * 100,
            0
        )
    INTO v_score
    FROM newsletters n
    JOIN newsletter_recipients nr ON nr.newsletter_id = n.id
    WHERE n.company_id = p_company_id;

    RETURN ROUND(v_score::NUMERIC, 2);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SEED DATA - Industry Templates
-- ============================================
INSERT INTO industry_templates (industry, suggested_topics, suggested_sources, suggested_competitors, suggested_keywords, newsletter_templates) VALUES

('Tech / SaaS / Logiciel',
'[
    {"name": "Intelligence Artificielle", "icon": "🤖", "keywords": ["ai", "artificial intelligence", "machine learning", "gpt", "llm", "deep learning"]},
    {"name": "Cloud & Infrastructure", "icon": "☁️", "keywords": ["cloud", "aws", "azure", "gcp", "kubernetes", "devops"]},
    {"name": "Startups & Funding", "icon": "🚀", "keywords": ["startup", "funding", "series a", "series b", "levee", "vc", "venture"]},
    {"name": "Product & UX", "icon": "🎨", "keywords": ["product", "ux", "ui", "design", "user experience", "feature"]},
    {"name": "Cybersecurite", "icon": "🔒", "keywords": ["security", "cyber", "hack", "breach", "vulnerability"]}
]'::jsonb,
'[
    {"type": "rss", "url": "https://techcrunch.com/feed/", "name": "TechCrunch"},
    {"type": "rss", "url": "https://www.theverge.com/rss/index.xml", "name": "The Verge"},
    {"type": "rss", "url": "https://feeds.feedburner.com/venturebeat/SZYF", "name": "VentureBeat"},
    {"type": "rss", "url": "https://www.maddyness.com/feed/", "name": "Maddyness"}
]'::jsonb,
'["Salesforce", "HubSpot", "Notion", "Slack", "Asana", "Monday.com"]'::jsonb,
'{"include": ["saas", "b2b", "startup", "tech"], "exclude": ["sponsored", "advertisement", "crypto"]}'::jsonb,
'[
    {"name": "Direction & Strategie", "target": "leadership", "topics": ["Startups & Funding", "Intelligence Artificielle"]},
    {"name": "Tech & Engineering", "target": "tech", "topics": ["Cloud & Infrastructure", "Cybersecurite", "Intelligence Artificielle"]},
    {"name": "Product & Design", "target": "product", "topics": ["Product & UX", "Intelligence Artificielle"]}
]'::jsonb
),

('Finance / Fintech / Banque',
'[
    {"name": "Fintech & Neobanques", "icon": "💳", "keywords": ["fintech", "neobank", "payment", "digital banking"]},
    {"name": "Crypto & Blockchain", "icon": "₿", "keywords": ["crypto", "bitcoin", "ethereum", "blockchain", "defi", "web3"]},
    {"name": "Marches & Trading", "icon": "📈", "keywords": ["market", "trading", "stock", "investment", "portfolio"]},
    {"name": "Regulation & Compliance", "icon": "⚖️", "keywords": ["regulation", "compliance", "sec", "amf", "rgpd", "aml"]},
    {"name": "InsurTech", "icon": "🛡️", "keywords": ["insurtech", "insurance", "assurance"]}
]'::jsonb,
'[
    {"type": "rss", "url": "https://www.coindesk.com/arc/outboundfeeds/rss/", "name": "CoinDesk"},
    {"type": "rss", "url": "https://fintech.global/feed/", "name": "Fintech Global"}
]'::jsonb,
'["Revolut", "N26", "Stripe", "Adyen", "Wise", "Qonto"]'::jsonb,
'{"include": ["fintech", "banking", "payment"], "exclude": ["sponsored"]}'::jsonb,
'[
    {"name": "Executive Brief", "target": "leadership", "topics": ["Marches & Trading", "Regulation & Compliance"]},
    {"name": "Fintech Watch", "target": "innovation", "topics": ["Fintech & Neobanques", "Crypto & Blockchain"]}
]'::jsonb
),

('Sante / Pharma / Biotech',
'[
    {"name": "Digital Health", "icon": "📱", "keywords": ["digital health", "telemedicine", "healthtech", "e-sante"]},
    {"name": "Pharma & Biotech", "icon": "💊", "keywords": ["pharma", "biotech", "drug", "clinical trial", "fda"]},
    {"name": "Medical Devices", "icon": "🔬", "keywords": ["medical device", "diagnostic", "imaging", "wearable"]},
    {"name": "Healthcare AI", "icon": "🤖", "keywords": ["ai health", "diagnostic ai", "medical imaging ai"]},
    {"name": "Regulation & FDA", "icon": "📋", "keywords": ["fda", "ema", "regulation", "approval", "clinical"]}
]'::jsonb,
'[
    {"type": "rss", "url": "https://www.fiercehealthcare.com/rss/xml", "name": "Fierce Healthcare"},
    {"type": "rss", "url": "https://www.statnews.com/feed/", "name": "STAT News"}
]'::jsonb,
'["Doctolib", "Withings", "Owkin", "Inato"]'::jsonb,
'{"include": ["healthcare", "medical", "health"], "exclude": ["sponsored", "webinar"]}'::jsonb,
'[
    {"name": "Healthcare Executive", "target": "leadership", "topics": ["Digital Health", "Regulation & FDA"]},
    {"name": "R&D Watch", "target": "research", "topics": ["Pharma & Biotech", "Healthcare AI"]}
]'::jsonb
);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletters ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletter_recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_stats ENABLE ROW LEVEL SECURITY;

-- RLS Policies (to be configured with Supabase Auth)
-- Example: Users can only access their company's data
-- CREATE POLICY "company_isolation" ON newsletters
--     FOR ALL USING (company_id = auth.jwt() ->> 'company_id');
