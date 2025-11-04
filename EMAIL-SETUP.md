# Email Configuration Guide

Complete guide for configuring email delivery in development and production environments.

## Table of Contents

1. [Development Setup (Mailhog)](#development-setup-mailhog)
2. [Production Setup (Real SMTP)](#production-setup-real-smtp)
3. [SMTP Provider Configuration](#smtp-provider-configuration)
4. [PrestaShop Email Configuration](#prestashop-email-configuration)
5. [Testing Email Delivery](#testing-email-delivery)
6. [Troubleshooting](#troubleshooting)

---

## Development Setup (Mailhog)

### What is Mailhog?

Mailhog is a local email testing tool that captures all outgoing emails without actually sending them. Perfect for development and testing.

**Features:**
- 📧 Catches all emails sent by PrestaShop
- 🌐 Web interface to view emails at `http://localhost:8025`
- 🚫 No real emails sent (safe testing)
- 🔍 Inspect email content, headers, and attachments

### Starting Mailhog

Mailhog starts automatically in development mode:

```bash
# Start all services including Mailhog
docker compose --profile dev up -d

# Or explicitly start with profile
COMPOSE_PROFILES=dev docker compose up -d
```

**Access Mailhog Web UI:**
- URL: http://localhost:8025
- SMTP Server: `mailhog:1025` (inside Docker network)
- SMTP Server: `localhost:1025` (from host machine)

### Development Environment Variables

In your `.env` file:

```bash
# SMTP Configuration - DEVELOPMENT
SMTP_HOST=mailhog
SMTP_PORT=1025
SMTP_USER=
SMTP_PASSWORD=
SMTP_ENCRYPTION=none
SMTP_AUTH=false
```

### How It Works

```
┌─────────────┐
│ PrestaShop  │
│  Container  │
└──────┬──────┘
       │ Sends email via SMTP
       │ to mailhog:1025
       ▼
┌─────────────┐
│   Mailhog   │  ◄─── View at http://localhost:8025
│  Container  │
└─────────────┘
       │
       ▼
   Emails are
   captured here
   (not sent)
```

---

## Production Setup (Real SMTP)

### Overview

In production, Mailhog is **completely disabled** and emails are sent through a real SMTP server.

**Recommended SMTP Providers:**
- **Gmail** - Free (500 emails/day), easy setup
- **SendGrid** - 100 emails/day free tier, great deliverability
- **AWS SES** - Pay-as-you-go, excellent for high volume
- **Mailgun** - Developer-friendly, good free tier
- **Brevo (Sendinblue)** - 300 emails/day free tier
- **Postmark** - Transactional email specialist

### Production Deployment

```bash
# Deploy with production configuration
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

Mailhog will **NOT** start in production mode.

### Production Environment Variables

In your `.env` file (copied from `.env.prod.example`):

```bash
# SMTP Configuration - PRODUCTION
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_ENCRYPTION=tls
SMTP_AUTH=true
```

**⚠️ Security Warning:**
- NEVER commit your real SMTP credentials to Git
- Use app-specific passwords (not your main account password)
- Rotate credentials regularly
- Use environment-specific credentials

---

## SMTP Provider Configuration

### Gmail

**Setup Steps:**
1. Enable 2-Factor Authentication on your Google Account
2. Generate an App Password: https://myaccount.google.com/apppasswords
3. Use the app password (not your regular password)

**Configuration:**
```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-16-char-app-password
SMTP_ENCRYPTION=tls
SMTP_AUTH=true
```

**Limitations:**
- 500 emails/day
- May require "Less secure app access" (not recommended)
- Better to use App Passwords with 2FA

**Cost:** Free

---

### SendGrid

**Setup Steps:**
1. Create account at https://sendgrid.com
2. Verify your sender identity (email or domain)
3. Create an API Key (Settings → API Keys)

**Configuration:**
```bash
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASSWORD=SG.xxxxxxxxxxxxxxxxxxxxxxx
SMTP_ENCRYPTION=tls
SMTP_AUTH=true
```

**Note:** The username is literally `apikey`, password is your actual API key.

**Limitations:**
- 100 emails/day (free tier)
- Domain verification recommended for better deliverability

**Cost:** Free tier, paid plans from $19.95/month

**Best for:** High deliverability requirements, marketing emails

---

### AWS SES (Simple Email Service)

**Setup Steps:**
1. Create AWS account
2. Verify email address or domain in SES console
3. Create SMTP credentials (IAM user)
4. Request production access (starts in sandbox mode)

**Configuration:**
```bash
SMTP_HOST=email-smtp.eu-west-1.amazonaws.com
SMTP_PORT=587
SMTP_USER=AKIAXXXXXXXXXXXXXXXX
SMTP_PASSWORD=Your-AWS-SMTP-Password
SMTP_ENCRYPTION=tls
SMTP_AUTH=true
```

**Limitations:**
- Sandbox: 200 emails/day to verified addresses only
- Production: Need to request limit increase
- Regional (choose closest region)

**Cost:** $0.10 per 1,000 emails (very cheap at scale)

**Best for:** High volume, cost-sensitive applications

---

### Mailgun

**Setup Steps:**
1. Create account at https://mailgun.com
2. Add and verify your domain
3. Get SMTP credentials from Sending → Domain Settings

**Configuration:**
```bash
SMTP_HOST=smtp.mailgun.org
SMTP_PORT=587
SMTP_USER=postmaster@your-domain.com
SMTP_PASSWORD=your-mailgun-smtp-password
SMTP_ENCRYPTION=tls
SMTP_AUTH=true
```

**Limitations:**
- Free tier: First 5,000 emails/month for 3 months
- Requires domain verification

**Cost:** Pay-as-you-go after trial

**Best for:** Developer-friendly API, good documentation

---

### Brevo (Sendinblue)

**Setup Steps:**
1. Create account at https://brevo.com
2. Verify email address
3. Get SMTP credentials from Settings → SMTP & API

**Configuration:**
```bash
SMTP_HOST=smtp-relay.brevo.com
SMTP_PORT=587
SMTP_USER=your-brevo-email@example.com
SMTP_PASSWORD=your-brevo-smtp-key
SMTP_ENCRYPTION=tls
SMTP_AUTH=true
```

**Limitations:**
- 300 emails/day (free tier)
- Includes Brevo logo in emails (free tier)

**Cost:** Free tier, paid plans from €25/month

**Best for:** European users, GDPR compliance

---

## PrestaShop Email Configuration

### Accessing Email Settings

1. Log in to PrestaShop Admin Panel
2. Navigate to: **Advanced Parameters → Email**
3. Configure email settings

### Configuration Options

#### Option 1: Use PHP's mail() Function (Not Recommended)

```
Email Settings → Technical Configuration
└─ Email: Select "Use PHP's mail() function"
```

**Issues:**
- Low deliverability (often marked as spam)
- No authentication
- Not suitable for production

---

#### Option 2: Use SMTP Server (Recommended)

```
Email Settings → Technical Configuration
└─ Email: Select "Set my own SMTP parameters"
```

**Fill in the following fields:**

| Field | Development (Mailhog) | Production (Gmail Example) |
|-------|----------------------|---------------------------|
| SMTP server | `mailhog` | `smtp.gmail.com` |
| SMTP username | (leave empty) | `your-email@gmail.com` |
| SMTP password | (leave empty) | `your-app-password` |
| Encryption | `none` | `TLS` |
| Port | `1025` | `587` |

**Important Notes:**
- Use the container name `mailhog` in development (not `localhost`)
- In production, use your SMTP provider's settings
- Enable TLS/SSL for production

### Email Templates

PrestaShop email templates location:
```
/var/www/html/mails/en/           # English templates
/var/www/html/mails/fr/           # French templates
```

To customize:
1. Copy template to your theme
2. Modify HTML/TXT versions
3. Test with Mailhog before deploying

---

## Testing Email Delivery

### Development Testing (Mailhog)

**1. Send Test Email from PrestaShop:**

```
Advanced Parameters → Email → Send a test email
```

**2. Check Mailhog Web UI:**

```bash
# Open in browser
http://localhost:8025
```

You should see the email captured.

**3. Test from Command Line:**

```bash
# Send test email using sendmail
docker exec prestashop php -r "mail('test@example.com', 'Test', 'Body');"
```

**4. Verify SMTP Connection:**

```bash
# Test SMTP connection from PrestaShop container
docker exec -it prestashop telnet mailhog 1025
```

Expected output:
```
220 mailhog.example ESMTP MailHog
```

Type `QUIT` to exit.

---

### Production Testing

**1. Send Test Email:**

Use PrestaShop's email test feature:
```
Advanced Parameters → Email → Send a test email
```

**2. Check Logs:**

```bash
# PrestaShop logs
docker exec prestashop tail -f /var/www/html/var/logs/*.log

# PHP errors
docker exec prestashop tail -f /var/log/php_errors.log
```

**3. Test SMTP Authentication:**

```bash
# Test SMTP connection
docker exec -it prestashop telnet smtp.gmail.com 587
```

**4. Use External Testing Tools:**

- **Mail Tester:** https://www.mail-tester.com/
  - Check spam score
  - Verify SPF, DKIM, DMARC

- **MXToolbox:** https://mxtoolbox.com/
  - Verify email deliverability
  - Check blacklists

---

## Troubleshooting

### Common Issues

#### 1. Emails Not Captured in Mailhog (Development)

**Symptoms:**
- Mailhog UI shows no emails
- PrestaShop shows email sent successfully

**Solutions:**

```bash
# Check if Mailhog is running
docker ps | grep mailhog

# Check Mailhog logs
docker logs mailhog

# Verify SMTP settings in PrestaShop
# Should be: mailhog:1025 with no authentication

# Restart Mailhog
docker restart mailhog
```

**Check Network Connectivity:**
```bash
# From PrestaShop container, test connection
docker exec prestashop ping -c 3 mailhog
docker exec prestashop telnet mailhog 1025
```

---

#### 2. SMTP Connection Failed (Production)

**Error:**
```
Connection could not be established with host smtp.gmail.com
```

**Solutions:**

**A. Check Firewall/Port:**
```bash
# Test if port is accessible
docker exec prestashop telnet smtp.gmail.com 587
```

**B. Verify Credentials:**
- Username correct (usually email address)
- Password correct (use app password for Gmail)
- SMTP server correct

**C. Check TLS/SSL Settings:**
- Port 587 → Use TLS
- Port 465 → Use SSL
- Never use `none` in production

**D. Review PHP SMTP Settings:**
```bash
# Check PHP can use sockets
docker exec prestashop php -r "echo extension_loaded('openssl') ? 'OK' : 'Missing';"
```

---

#### 3. Emails Marked as Spam

**Causes:**
- No SPF record
- No DKIM signature
- No DMARC policy
- From address doesn't match domain

**Solutions:**

**A. Configure SPF Record (DNS):**
```
Type: TXT
Name: @
Value: v=spf1 include:_spf.google.com ~all
```

**B. Configure DKIM (via SMTP provider):**
- Enable in SendGrid/AWS SES settings
- Add DKIM DNS records provided by your SMTP provider

**C. Configure DMARC (DNS):**
```
Type: TXT
Name: _dmarc
Value: v=DMARC1; p=quarantine; rua=mailto:postmaster@yourdomain.com
```

**D. Use Matching From Address:**
- If using `shop.com`, send from `noreply@shop.com`
- Not `something@gmail.com`

---

#### 4. Mailhog Port Already in Use

**Error:**
```
Error: Port 1025 is already allocated
```

**Solution:**
```bash
# Find process using port
lsof -i :1025  # Linux/Mac
netstat -ano | findstr :1025  # Windows

# Kill the process or change port in docker-compose.yml
ports:
  - "1026:1025"  # Changed host port
  - "8025:8025"
```

---

#### 5. Cannot Access Mailhog Web UI

**Symptoms:**
- `http://localhost:8025` not loading

**Solutions:**

```bash
# Check if Mailhog is running
docker ps | grep mailhog

# Check port mapping
docker port mailhog

# Access via Docker network (from another container)
docker exec prestashop curl http://mailhog:8025
```

---

### Debug Mode

Enable debug output in PrestaShop:

```php
// In PrestaShop admin: Advanced Parameters → Performance
// Enable Debug mode
```

Or edit `config/defines.inc.php`:
```php
define('_PS_MODE_DEV_', true);
```

---

## Best Practices

### Development

✅ **Do:**
- Use Mailhog for all email testing
- Test all email templates before production
- Check HTML and plain text versions
- Verify email content and formatting

❌ **Don't:**
- Use real SMTP in development
- Send test emails to real addresses
- Hardcode email addresses in code

---

### Production

✅ **Do:**
- Use reputable SMTP provider
- Enable SPF/DKIM/DMARC
- Use app-specific passwords
- Monitor email deliverability
- Set up bounce handling
- Keep credentials in `.env` (never commit)
- Use TLS/SSL encryption
- Verify sender domain
- Monitor daily sending limits

❌ **Don't:**
- Use Gmail personal account for high volume
- Commit credentials to Git
- Use `none` encryption
- Ignore bounce rates
- Send without authentication
- Use PHP mail() function

---

## Monitoring Email Delivery

### Check Delivery Rates

**SendGrid:**
```
Dashboard → Activity Feed
```

**AWS SES:**
```
SES Console → Reputation Dashboard
```

**Gmail:**
```
Check sent folder (limited visibility)
```

### Important Metrics

- **Delivery Rate:** Should be > 95%
- **Bounce Rate:** Should be < 5%
- **Spam Complaint Rate:** Should be < 0.1%

### Alerts

Set up alerts for:
- High bounce rates
- SMTP authentication failures
- Daily limit approaching
- Low deliverability

---

## Security Checklist

- [ ] SMTP credentials stored in `.env` (not committed)
- [ ] Using app-specific passwords (not main account)
- [ ] TLS/SSL enabled in production
- [ ] SPF record configured
- [ ] DKIM signatures enabled
- [ ] DMARC policy set
- [ ] Sender domain verified
- [ ] Regular credential rotation
- [ ] Monitoring enabled
- [ ] Mailhog disabled in production

---

## Additional Resources

### Documentation
- **Mailhog:** https://github.com/mailhog/MailHog
- **PrestaShop Email:** https://devdocs.prestashop-project.org/
- **SMTP RFC:** https://tools.ietf.org/html/rfc5321

### Tools
- **Mail Tester:** https://www.mail-tester.com/
- **MXToolbox:** https://mxtoolbox.com/
- **DMARCian:** https://dmarcian.com/

### Tutorials
- **Gmail App Passwords:** https://support.google.com/accounts/answer/185833
- **SendGrid Setup:** https://docs.sendgrid.com/
- **AWS SES Setup:** https://docs.aws.amazon.com/ses/

---

## Quick Reference

### Commands

```bash
# Development: Start with Mailhog
docker compose --profile dev up -d

# Production: Deploy without Mailhog
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# View Mailhog logs
docker logs mailhog

# Test SMTP connection
docker exec prestashop telnet mailhog 1025

# Check PrestaShop email logs
docker exec prestashop tail -f /var/www/html/var/logs/*.log

# Restart PrestaShop (reload SMTP config)
docker restart prestashop
```

### URLs

- **Mailhog Web UI:** http://localhost:8025
- **PrestaShop Email Settings:** Admin → Advanced Parameters → Email

---

**Last Updated:** 2025-11-04
