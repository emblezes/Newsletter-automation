# Newsletter SaaS - API Documentation

## Authentication

All API requests require authentication using an API key.

```bash
curl -X POST https://your-n8n.com/webhook/newsletter/send \
  -H "X-API-Key: nla_abc123xyz789" \
  -H "Content-Type: application/json" \
  -d '{"newsletter_id": "uuid-here"}'
```

API keys are generated automatically when a client account is created.

---

## Endpoints

### Send Newsletter

Manually trigger a newsletter to be sent immediately.

```
POST /webhook/newsletter/send
```

**Headers:**
| Header | Required | Description |
|--------|----------|-------------|
| X-API-Key | Yes | Client API key |
| Content-Type | Yes | application/json |

**Body:**
```json
{
  "newsletter_id": "660e8400-e29b-41d4-a716-446655440001"
}
```

**Response (Success):**
```json
{
  "success": true,
  "newsletter_id": "660e8400-e29b-41d4-a716-446655440001",
  "newsletter_name": "Daily Tech Digest",
  "articles_sent": 12,
  "recipients": 150,
  "channels": ["email", "telegram"],
  "delivered_at": "2026-01-18T07:30:00.000Z"
}
```

**Response (No Articles):**
```json
{
  "success": true,
  "message": "No articles found for today",
  "articles_sent": 0
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "Newsletter not found or unauthorized",
  "code": "UNAUTHORIZED"
}
```

---

## Database Tables

### clients
SaaS customer accounts.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| email | TEXT | Unique email |
| company_name | TEXT | Company name |
| plan | TEXT | free, starter, pro, enterprise |
| api_key | TEXT | Unique API key (nla_...) |
| newsletters_limit | INT | Max newsletters allowed |
| emails_per_month | INT | Monthly email limit |
| is_active | BOOL | Account active status |

### newsletters
Newsletter configurations per client.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| client_id | UUID | FK to clients |
| name | TEXT | Newsletter name |
| industry | TEXT | Industry type |
| is_active | BOOL | Newsletter active |
| schedule_enabled | BOOL | Auto-schedule on/off |
| schedule_hour | INT | Hour to send (0-23) |
| schedule_minute | INT | Minute to send (0-59) |
| schedule_timezone | TEXT | Timezone (e.g., Europe/Paris) |
| schedule_days | INT[] | Days to send (0=Sun, 1=Mon...) |
| max_articles | INT | Max articles per newsletter |
| ai_summaries_enabled | BOOL | Enable AI summaries |

### newsletter_branding
Visual branding per newsletter.

| Column | Type | Description |
|--------|------|-------------|
| newsletter_id | UUID | PK, FK to newsletters |
| title | TEXT | Newsletter title |
| subtitle | TEXT | Subtitle/tagline |
| logo_url | TEXT | Logo image URL |
| primary_color | TEXT | Header gradient start |
| secondary_color | TEXT | Header gradient end |
| footer_text | TEXT | Footer message |
| social_links | JSONB | Social media links |

### newsletter_sources
News sources configuration.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| newsletter_id | UUID | FK to newsletters |
| source_type | TEXT | rss, newsapi, custom_api |
| source_url | TEXT | RSS feed URL |
| keywords | TEXT[] | NewsAPI search keywords |
| exclude_keywords | TEXT[] | Words to filter out |
| is_active | BOOL | Source active |

### newsletter_categories
Custom categories per newsletter.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| newsletter_id | UUID | FK to newsletters |
| name | TEXT | Category name |
| icon | TEXT | Emoji icon |
| color | TEXT | Hex color code |
| keywords | TEXT[] | AI categorization keywords |
| sort_order | INT | Display order |

### newsletter_recipients
Email subscribers.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| newsletter_id | UUID | FK to newsletters |
| email | TEXT | Subscriber email |
| name | TEXT | Subscriber name |
| is_active | BOOL | Subscribed status |
| subscribed_at | TIMESTAMP | Subscription date |

### newsletter_channels
Delivery channels configuration.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| newsletter_id | UUID | FK to newsletters |
| channel_type | TEXT | email, telegram, slack, discord |
| is_enabled | BOOL | Channel enabled |
| config | JSONB | Channel-specific settings |

**Channel Config Examples:**

Email:
```json
{
  "from_name": "Company Newsletter",
  "from_email": "newsletter@company.com",
  "reply_to": "hello@company.com"
}
```

Telegram:
```json
{
  "chat_id": "-1001234567890"
}
```

Slack:
```json
{
  "webhook_url": "https://hooks.slack.com/services/..."
}
```

### delivery_logs
Delivery history for analytics and billing.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| client_id | UUID | FK to clients |
| newsletter_id | UUID | FK to newsletters |
| delivered_at | TIMESTAMP | Delivery timestamp |
| trigger_type | TEXT | scheduled, manual, api, test |
| status | TEXT | success, partial, failed |
| articles_count | INT | Articles sent |
| recipients_count | INT | Recipients count |
| channels_used | TEXT[] | Channels used |
| execution_time_ms | INT | Processing time |
| error_message | TEXT | Error details if failed |

### usage_stats
Monthly usage metrics for billing.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| client_id | UUID | FK to clients |
| month | DATE | First of month |
| newsletters_sent | INT | Total newsletters |
| emails_sent | INT | Total emails |
| telegram_messages | INT | Telegram messages |
| ai_tokens_used | INT | OpenAI tokens |

---

## Pricing Plans

| Plan | Newsletters | Emails/Month | Features |
|------|-------------|--------------|----------|
| Free | 1 | 500 | Basic features |
| Starter | 3 | 2,000 | + Custom branding |
| Pro | 10 | 10,000 | + All channels, API access |
| Enterprise | Unlimited | Unlimited | + Custom integrations |

---

## Webhook Events (Future)

For integrating with your frontend, these webhook events can be configured:

```json
{
  "event": "newsletter.sent",
  "payload": {
    "newsletter_id": "...",
    "articles_count": 12,
    "recipients_count": 150,
    "status": "success"
  }
}
```

Events:
- `newsletter.sent` - Newsletter successfully delivered
- `newsletter.failed` - Newsletter delivery failed
- `subscriber.added` - New subscriber added
- `subscriber.removed` - Subscriber unsubscribed
- `usage.limit_warning` - Approaching usage limit (80%)
- `usage.limit_reached` - Usage limit reached
