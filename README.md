# N8N Newsletter Automation

Automated industry-specific newsletter workflow that curates news from multiple sources and delivers it via Email and Telegram every morning. Supports both single-client and multi-client (agency) modes.

## Features

- **Multi-Client Support**: Manage unlimited clients with different industries
- **Per-Client Branding**: Custom colors, logos, and newsletter titles
- **Industry-Specific Categories**: AI-powered categorization with custom categories per client
- **Scheduled Delivery**: Configurable send times per client
- **Dual Channel Delivery**: Email and/or Telegram per client preference
- **AI-Powered Summaries**: Automatic article summarization and importance scoring

## Available Workflows

| Workflow | File | Use Case |
|----------|------|----------|
| Single Client | `newsletter-automation.json` | One company, one industry |
| Multi-Client | `newsletter-multi-client.json` | Agency managing multiple clients |

---

## Multi-Client Mode (Agency)

Perfect for agencies or companies managing newsletters for multiple clients.

### Architecture

```
Morning Schedule (6:00 AM)
         │
    Load All Clients
         │
    ┌────┴────┐
    │  LOOP   │ ◄─────────────────────────────────┐
    └────┬────┘                                   │
         │                                        │
    For Each Client:                              │
         │                                        │
    ┌────┴────┐                                   │
    │ Client  │──► Fetch News (Keywords + RSS)    │
    │ Config  │         │                         │
    └─────────┘         ▼                         │
              AI Categorize (Client Categories)   │
                        │                         │
                        ▼                         │
              ┌─────────┴─────────┐               │
              ▼                   ▼               │
        Format Email       Format Telegram        │
        (Client Brand)     (Client Brand)         │
              │                   │               │
              ▼                   ▼               │
         Send Email?        Send Telegram?        │
         (if enabled)       (if enabled)          │
              │                   │               │
              └─────────┬─────────┘               │
                        │                         │
                   Log Delivery                   │
                        │                         │
                        └─────────────────────────┘
                        │
                   Final Summary
```

### Client Configuration

Each client has their own complete configuration in `config/clients.json`:

```json
{
  "id": "client-001",
  "name": "TechVentures Inc",
  "active": true,
  "industry": "Technology",
  "branding": {
    "companyName": "TechVentures Inc",
    "newsletterTitle": "Tech Ventures Daily",
    "primaryColor": "#667eea",
    "secondaryColor": "#764ba2"
  },
  "sources": {
    "keywords": "AI, machine learning, cloud computing",
    "rssFeeds": ["https://feeds.feedburner.com/TechCrunch/"],
    "excludeKeywords": ["sponsored", "advertisement"]
  },
  "categories": {
    "AI & ML": { "icon": "🤖", "color": "#8B5CF6", "keywords": ["ai", "machine learning"] },
    "Cloud": { "icon": "☁️", "color": "#0EA5E9", "keywords": ["cloud", "aws", "azure"] }
  },
  "delivery": {
    "email": {
      "enabled": true,
      "recipients": ["team@client.com"]
    },
    "telegram": {
      "enabled": true,
      "chatId": "-1001234567001"
    }
  },
  "preferences": {
    "maxArticles": 12,
    "aiSummaries": true
  }
}
```

### Pre-Configured Clients (Examples)

| Client | Industry | Categories | Delivery |
|--------|----------|------------|----------|
| TechVentures Inc | Technology | AI, Cloud, Startups, Dev | Email + Telegram |
| FinanceFirst Bank | Finance | Fintech, Crypto, Markets, Regulation | Email + Telegram |
| MedTech Solutions | Healthcare | Pharma, Digital Health, Devices | Email only |
| EcoEnergy Corp | Energy | Solar, EVs, Policy, Storage | Email + Telegram |
| RetailMax Group | E-commerce | E-commerce, Supply Chain, Retail Tech | Email only |

### Adding a New Client

1. Open `config/clients.json`
2. Copy the template from `templates.newClient`
3. Customize all fields for your new client
4. Set `active: true` to enable
5. The workflow will automatically include them in the next run

### Client-Specific Branding

Each email is fully branded for the client:

```
┌─────────────────────────────────────────────────┐
│  ▓▓▓ CLIENT PRIMARY → SECONDARY GRADIENT ▓▓▓   │
│         Client's Newsletter Title               │
│         Client's Industry Updates               │
├─────────────────────────────────────────────────┤
│  📋 IN THIS ISSUE                               │
│  [Client's Category 1] [Category 2] [...]       │
├─────────────────────────────────────────────────┤
│  ⭐ TOP STORY                                   │
│  (AI-selected most important article)           │
├─────────────────────────────────────────────────┤
│  🤖 CLIENT CATEGORY 1 ─────── (color-coded)    │
│  ├── Article with AI summary                    │
│  └── Article with AI summary                    │
│                                                 │
│  ☁️ CLIENT CATEGORY 2 ─────── (color-coded)    │
│  └── ...                                        │
├─────────────────────────────────────────────────┤
│  Curated for [Client Company Name]              │
└─────────────────────────────────────────────────┘
```

---

## Single Client Mode

For companies managing their own newsletter.

### Quick Start

1. Import `workflows/newsletter-automation.json`
2. Configure credentials (NewsAPI, SMTP, Telegram, OpenAI)
3. Set environment variables
4. Activate workflow

### Environment Variables

```bash
# Industry Settings
INDUSTRY_NAME=Technology
INDUSTRY_KEYWORDS=AI, machine learning, cloud computing
NEWSLETTER_TITLE=Daily Tech Digest
COMPANY_NAME=Your Company

# Recipients
EMAIL_RECIPIENTS=team@company.com
TELEGRAM_CHAT_ID=-1001234567890

# RSS Feeds
RSS_FEEDS=https://feeds.feedburner.com/TechCrunch/
```

---

## Required Credentials

### 1. NewsAPI
```
Type: HTTP Header Auth
Name: NewsAPI Credentials
Header: X-Api-Key
Value: your_api_key_from_newsapi.org
```

### 2. OpenAI (for AI categorization)
```
Type: OpenAI API
Name: OpenAI Credentials
API Key: your_openai_api_key
```

### 3. SMTP (Email)
```
Type: SMTP
Host: smtp.gmail.com (or your provider)
Port: 587
User: your-email@gmail.com
Password: app_password
```

### 4. Telegram Bot
```
Type: Telegram API
Bot Token: from @BotFather
```

---

## Industry Presets

Pre-configured in `config/industries.json`:

| Industry | Icon | Example Keywords |
|----------|------|------------------|
| Technology | 💻 | AI, cloud, software, startups |
| Finance | 💳 | fintech, crypto, markets, banking |
| Healthcare | 💊 | pharma, biotech, digital health |
| E-commerce | 🛒 | retail, logistics, supply chain |
| Energy | ⚡ | solar, wind, EVs, sustainability |
| Manufacturing | 🏭 | IoT, Industry 4.0, robotics |
| Real Estate | 🏢 | proptech, commercial RE |
| Marketing | 📢 | adtech, SEO, social media |

---

## File Structure

```
Newsletter-automation/
├── workflows/
│   ├── newsletter-automation.json      # Single-client workflow
│   └── newsletter-multi-client.json    # Multi-client workflow
├── config/
│   ├── clients.json                    # Multi-client configurations
│   └── industries.json                 # Industry presets
├── .env.example                        # Environment template
└── README.md                           # This file
```

---

## API Limits & Costs

| Service | Free Tier | Notes |
|---------|-----------|-------|
| NewsAPI | 100 req/day | ~6-7 clients/day with 15 articles each |
| OpenAI GPT-4o-mini | ~$0.15/1M tokens | Very affordable for categorization |
| Telegram | 30 msg/sec | More than enough |
| SMTP | Varies | Check your provider |

For high-volume (many clients), consider:
- NewsAPI paid plan ($449/mo unlimited)
- Caching news results
- Staggered sending times

---

## Troubleshooting

### Multi-Client Issues

**Client not receiving newsletter:**
- Check `active: true` in client config
- Verify email recipients are correct
- Check Telegram chatId (must include `-` for groups)

**Wrong articles for client:**
- Review keywords in `sources.keywords`
- Check `excludeKeywords` isn't too aggressive
- Verify RSS feeds are correct for industry

**Branding not showing:**
- Ensure `branding.primaryColor` is valid hex
- Check `branding.newsletterTitle` is set

### General Issues

**AI categorization failing:**
- Check OpenAI credentials
- Verify API key has credits
- Fallback keyword categorization will work

**No articles appearing:**
- Check NewsAPI key validity
- Verify RSS feeds are accessible
- Check network from N8N server

---

## License

MIT License - use and modify freely.
