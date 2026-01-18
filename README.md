# N8N Newsletter Automation

Automated industry-specific newsletter workflow that curates news from multiple sources and delivers it via Email and Telegram every morning.

## Features

- **Scheduled Delivery**: Automatically runs every morning at your configured time
- **Multi-Source Aggregation**: Pulls from NewsAPI and RSS feeds
- **Industry Presets**: Pre-configured for 8 industries (Tech, Finance, Healthcare, etc.)
- **Dual Channel Delivery**: Sends beautiful HTML emails and formatted Telegram messages
- **Customizable**: Easy configuration via environment variables
- **Error Handling**: Built-in logging and error management

## Workflow Overview

```
Morning Schedule (7:00 AM)
    │
    ▼
Load Configuration
    │
    ├──────────────────┐
    ▼                  ▼
Fetch NewsAPI    Fetch RSS Feeds
    │                  │
    └────────┬─────────┘
             ▼
    Process & Merge News
             │
             ▼
       Has Articles?
        │        │
       YES      NO
        │        │
   ┌────┴────┐   └──→ Skip
   ▼         ▼
Format    Format
Email     Telegram
   │         │
   ▼         ▼
Send      Send
Email     Telegram
   │         │
   └────┬────┘
        ▼
   Log Success
```

## Quick Start

### 1. Prerequisites

- [N8N](https://n8n.io/) installed (self-hosted or cloud)
- [NewsAPI](https://newsapi.org/) account (free tier available)
- Email SMTP access (Gmail, SendGrid, etc.)
- Telegram Bot (optional, for Telegram delivery)

### 2. Import Workflow

1. Open your N8N instance
2. Go to **Workflows** → **Import from File**
3. Select `workflows/newsletter-automation.json`
4. Click **Import**

### 3. Configure Credentials

#### NewsAPI
1. Go to [newsapi.org](https://newsapi.org) and sign up
2. Copy your API key
3. In N8N, go to **Credentials** → **New** → **HTTP Header Auth**
4. Name: `NewsAPI Credentials`
5. Header Name: `X-Api-Key`
6. Header Value: `your_api_key`

#### Email (SMTP)
1. Go to **Credentials** → **New** → **SMTP**
2. Configure with your email provider:

   **Gmail Example:**
   - Host: `smtp.gmail.com`
   - Port: `587`
   - User: `your-email@gmail.com`
   - Password: [App Password](https://support.google.com/accounts/answer/185833)
   - SSL/TLS: `true`

   **SendGrid Example:**
   - Host: `smtp.sendgrid.net`
   - Port: `587`
   - User: `apikey`
   - Password: `your_sendgrid_api_key`

#### Telegram Bot
1. Message [@BotFather](https://t.me/BotFather) on Telegram
2. Send `/newbot` and follow instructions
3. Copy the bot token
4. In N8N: **Credentials** → **New** → **Telegram API**
5. Paste your bot token

**Get your Chat ID:**
- Add [@userinfobot](https://t.me/userinfobot) to your group/channel
- Or use [@getidsbot](https://t.me/getidsbot)
- For channels: the ID will be negative (e.g., `-1001234567890`)

### 4. Configure Environment Variables

Set these environment variables in your N8N instance:

```bash
# Industry Settings
INDUSTRY_NAME=Technology
INDUSTRY_KEYWORDS=AI, machine learning, cloud computing
NEWSLETTER_TITLE=Daily Tech Digest
COMPANY_NAME=Your Company

# Recipients
EMAIL_RECIPIENTS=team@company.com
TELEGRAM_CHAT_ID=-1001234567890

# RSS Feeds (comma-separated)
RSS_FEEDS=https://feeds.feedburner.com/TechCrunch/
```

### 5. Activate Workflow

1. Open the imported workflow
2. Click **Active** toggle in the top right
3. The workflow will now run daily at 7:00 AM

## Industry Presets

Choose from pre-configured industry settings in `config/industries.json`:

| Industry | Keywords | Sample RSS Feeds |
|----------|----------|------------------|
| Technology | AI, ML, cloud, cybersecurity | TechCrunch, The Verge, Wired |
| Finance | fintech, crypto, investing | FT, Bloomberg, CoinDesk |
| Healthcare | pharma, biotech, digital health | Fierce Healthcare, Health IT News |
| E-commerce | retail, logistics, supply chain | Retail Dive, E-commerce Times |
| Manufacturing | Industry 4.0, IoT, robotics | Industry Week, Automation World |
| Energy | renewable, solar, EVs | GTM, CleanTechnica |
| Real Estate | proptech, commercial RE | Bisnow |
| Marketing | adtech, SEO, social media | Mashable, Adweek |

## Customization

### Change Schedule Time

Edit the **Morning Schedule** node:
```json
{
  "rule": {
    "interval": [
      {
        "triggerAtHour": 9,  // Change to your preferred hour (24h format)
        "triggerAtMinute": 0
      }
    ]
  }
}
```

### Add More RSS Feeds

Update the `RSS_FEEDS` environment variable or modify the RSS feed list in the configuration.

### Customize Email Template

Edit the **Format Email Newsletter** code node to modify:
- Colors and branding
- Layout structure
- Number of articles shown
- Footer content

### Adjust Article Count

In the **Process & Merge News** node, change:
```javascript
.slice(0, 10)  // Change 10 to your desired number
```

## Troubleshooting

### No articles appearing
- Check NewsAPI key is valid
- Verify RSS feed URLs are accessible
- Check network connectivity from N8N server

### Email not sending
- Verify SMTP credentials
- Check spam folder
- For Gmail: ensure "Less secure app access" or use App Password

### Telegram not working
- Verify bot token is correct
- Ensure bot is added to the channel/group
- Check chat ID is correct (include `-` for groups)

### Workflow not triggering
- Ensure workflow is **Active**
- Check N8N server timezone settings
- Verify schedule node configuration

## File Structure

```
Newsletter-automation/
├── workflows/
│   └── newsletter-automation.json   # Main N8N workflow
├── config/
│   └── industries.json              # Industry presets
├── .env.example                     # Environment template
└── README.md                        # This file
```

## API Limits

| Service | Free Tier Limit |
|---------|-----------------|
| NewsAPI | 100 requests/day |
| Telegram | 30 messages/second |
| Most SMTP | Varies by provider |

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - feel free to use and modify for your needs.

## Support

For issues and feature requests, please open a GitHub issue.
