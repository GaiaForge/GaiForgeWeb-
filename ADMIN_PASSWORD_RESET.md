# Admin Password Reset Guide

## Manual Password Reset (Admin Panel)

If automatic password reset emails aren't working, you can now manually reset user passwords through the admin panel.

### How to Use

1. Log in to the admin panel at `/admin`
2. Navigate to the **Users** tab
3. Find the user who needs a password reset
4. Click the **Reset Password** button in their row
5. A secure random password will be generated and displayed
6. **IMPORTANT:** Copy the password immediately - it cannot be recovered after closing the modal
7. Send the password to the user via a secure channel (phone, secure messaging, etc.)
8. Instruct the user to change their password after logging in

### Features

- Generates a secure 16-character random password
- Copy to clipboard functionality
- Warning before closing to ensure password is saved
- Admin audit log entry for security tracking

---

## Debugging Automatic Email Issues

If the automatic "Forgot Password" email system isn't working, check these common issues:

### 1. Backend API Email Configuration

The backend API needs to be configured with email settings. Check the following environment variables on your server:

```bash
# SMTP Server Configuration
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=noreply@gaiaforge.com
SMTP_PASSWORD=your_smtp_password
SMTP_FROM=noreply@gaiaforge.com

# Or for services like SendGrid, Mailgun, etc:
SENDGRID_API_KEY=your_api_key
```

### 2. Check Backend Logs

SSH into your server and check the backend API logs:

```bash
# If using systemd
sudo journalctl -u gaiaforge-api -n 100 --no-pager

# If using PM2
pm2 logs gaiaforge-api

# If using Docker
docker logs gaiaforge-backend
```

Look for errors related to:
- SMTP connection failures
- Authentication errors
- Email sending failures

### 3. Test Email Endpoint

You can test if the backend can send emails by checking the forgot password endpoint directly:

```bash
curl -X POST https://your-domain.com/api/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'
```

A successful response should return `200 OK` even if the email doesn't exist (security feature).

### 4. Common Email Issues

#### SMTP Authentication Failed
- Verify SMTP credentials are correct
- Check if your SMTP provider requires app-specific passwords (Gmail, Outlook)
- Ensure 2FA is configured properly if required

#### Emails Going to Spam
- Configure SPF, DKIM, and DMARC records for your domain
- Use a verified sending domain
- Avoid sending from `@gmail.com` or `@yahoo.com` addresses

#### Connection Timeout
- Check firewall rules allow outbound SMTP (port 587 or 465)
- Verify your VPS provider doesn't block SMTP ports
- Try using an email service API (SendGrid, Mailgun) instead of direct SMTP

#### Rate Limiting
- Check if your email provider has rate limits
- Implement exponential backoff for retries
- Consider using a dedicated email service

### 5. Check Database for Reset Tokens

If emails aren't being received, verify that reset tokens are being created in the database:

```sql
-- Connect to your PostgreSQL database
psql -U your_db_user -d gaiaforge

-- Check recent password reset tokens
SELECT user_id, created_at, expires_at 
FROM password_reset_tokens 
ORDER BY created_at DESC 
LIMIT 10;
```

If tokens are being created but emails aren't sending, the issue is with email delivery.

### 6. Backend Code Location

The email sending logic should be in your backend API code. Look for:

```python
# Typical FastAPI structure
/api/auth/forgot-password  # Endpoint
/services/email_service.py  # Email sending logic
/config.py                  # SMTP configuration
```

### 7. Alternative: Use Email Service API

Instead of SMTP, consider using an email service API which is more reliable:

**SendGrid Example:**
```python
import sendgrid
from sendgrid.helpers.mail import Mail

def send_reset_email(to_email, reset_link):
    message = Mail(
        from_email='noreply@gaiaforge.com',
        to_emails=to_email,
        subject='Reset Your GaiaForge Password',
        html_content=f'<a href="{reset_link}">Reset Password</a>'
    )
    sg = sendgrid.SendGridAPIClient(api_key=os.environ.get('SENDGRID_API_KEY'))
    response = sg.send(message)
    return response.status_code
```

**Mailgun Example:**
```python
import requests

def send_reset_email(to_email, reset_link):
    return requests.post(
        f"https://api.mailgun.net/v3/{MAILGUN_DOMAIN}/messages",
        auth=("api", MAILGUN_API_KEY),
        data={
            "from": "GaiaForge <noreply@gaiaforge.com>",
            "to": [to_email],
            "subject": "Reset Your Password",
            "html": f'<a href="{reset_link}">Reset Password</a>'
        }
    )
```

### 8. Quick Fix: Add Manual Email Notification

If you need a quick workaround, you can modify the backend to also log reset links to a file or admin notification system when automated emails fail.

---

## Security Best Practices

1. **Never send passwords via regular email** - Use the secure channel for manual resets
2. **Rotate admin credentials regularly**
3. **Monitor the audit log** for suspicious password reset activity
4. **Use strong SMTP credentials** and rotate them periodically
5. **Enable rate limiting** on password reset endpoints to prevent abuse

---

## Support

If issues persist after following this guide, check:

1. Backend API repository documentation
2. Server logs in `/var/log/`
3. Email provider's delivery logs
4. Contact your email service provider's support

For urgent issues, use the manual password reset feature in the admin panel as a workaround.
