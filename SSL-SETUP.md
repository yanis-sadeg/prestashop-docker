# SSL Configuration with Traefik and Let's Encrypt

This guide explains how to use SSL in development and transition to production with Let's Encrypt.

## Architecture

- **Traefik**: Reverse proxy with automatic SSL certificate management
- **Let's Encrypt**: Free certificate authority for SSL certificates
- **Hybrid mode**: Self-signed certificates in dev, Let's Encrypt in production

## Development (localhost)

### Service Access

With the current configuration:

- PrestaShop HTTP: http://localhost
- PrestaShop HTTPS: https://localhost (self-signed certificate)
- Traefik Dashboard: http://localhost:8080
- phpMyAdmin: http://localhost:8081

### Self-Signed Certificate

In development, Traefik automatically generates a self-signed certificate. Your browser will display a security warning, which is normal.

**To accept the certificate:**
- Chrome/Edge: Click "Advanced" then "Continue to localhost (unsafe)"
- Firefox: Click "Advanced" then "Accept the Risk and Continue"

### Startup

```bash
docker-compose up -d
```

## Production (with real domain)

### Prerequisites

1. **Domain name** pointing to your server
2. **Open ports**: 80 and 443 accessible from the Internet
3. **DNS configured**: A or CNAME record pointing to your server's IP

### Configuration

#### 1. Modify the .env file

```bash
# Domain configuration
DOMAIN=your-domain.com

# Email for Let's Encrypt
LETSENCRYPT_EMAIL=your-email@example.com
```

#### 2. Enable Let's Encrypt in docker-compose.yml

In [docker-compose.yml](docker-compose.yml), for the `prestashop` service, **uncomment** the Let's Encrypt lines:

```yaml
# HTTPS Configuration (uncomment for production with Let's Encrypt)
- "traefik.http.routers.prestashop-secure.rule=Host(`${DOMAIN:-localhost}`)"
- "traefik.http.routers.prestashop-secure.entrypoints=websecure"
- "traefik.http.routers.prestashop-secure.tls=true"
- "traefik.http.routers.prestashop-secure.tls.certresolver=letsencrypt"
```

And **comment** the self-signed certificate lines:

```yaml
# HTTPS Configuration with self-signed certificate (dev)
# - "traefik.http.routers.prestashop-secure.rule=Host(`${DOMAIN:-localhost}`)"
# - "traefik.http.routers.prestashop-secure.entrypoints=websecure"
# - "traefik.http.routers.prestashop-secure.tls=true"
```

#### 3. (Optional) Enable HTTP → HTTPS Redirect

In [docker/traefik/traefik.yml](docker/traefik/traefik.yml), uncomment:

```yaml
entryPoints:
  web:
    address: ":80"
    # HTTP to HTTPS redirect (uncomment for production)
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
```

#### 4. Disable Traefik Dashboard Insecure Mode

In [docker/traefik/traefik.yml](docker/traefik/traefik.yml), modify:

```yaml
api:
  dashboard: true
  insecure: false  # Secure dashboard in production
```

#### 5. Restart Services

```bash
docker-compose down
docker-compose up -d
```

### Verification

1. Access `https://your-domain.com`
2. The SSL certificate should be valid (green padlock in browser)
3. Verify at https://www.ssllabs.com/ssltest/ for a complete audit

### Automatic Renewal

Let's Encrypt generates certificates valid for 90 days. Traefik automatically handles renewal, no manual action is required.

## Let's Encrypt Staging Test (recommended before production)

To test Let's Encrypt configuration without using the production quota:

In [docker/traefik/traefik.yml](docker/traefik/traefik.yml), uncomment:

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: ${LETSENCRYPT_EMAIL:-admin@localhost}
      storage: /letsencrypt/acme.json
      # Use caServer for Let's Encrypt staging (dev/test)
      caServer: https://acme-staging-v02.api.letsencrypt.org/directory
      httpChallenge:
        entryPoint: web
```

The certificate will be issued by "Fake LE Intermediate X1" but will allow you to validate that everything works.

## Troubleshooting

### Let's Encrypt Certificate Doesn't Generate

1. Verify that the domain points to your server: `nslookup your-domain.com`
2. Verify that port 80 is accessible: `curl http://your-domain.com`
3. Check Traefik logs: `docker logs traefik`
4. Verify acme.json file: `cat docker/traefik/letsencrypt/acme.json`

### Error "too many certificates already issued"

You've reached the Let's Encrypt limit (5 certificates per domain per week). Use staging while validating your configuration.

### Browser Still Shows Warning

- In dev with self-signed certificate: this is normal
- In prod with Let's Encrypt: verify that you've properly enabled Let's Encrypt configuration in docker-compose.yml

## Resources

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Let's Encrypt](https://letsencrypt.org/)
- [Let's Encrypt Limits](https://letsencrypt.org/docs/rate-limits/)

## File Structure

```
prestashop/
├── docker-compose.yml              # Service configuration
├── .env                            # Environment variables (to create)
├── .env.example                    # Configuration example
├── docker/
│   └── traefik/
│       ├── traefik.yml            # Traefik configuration
│       └── letsencrypt/
│           └── acme.json          # Let's Encrypt certificate storage
└── SSL-SETUP.md                   # This file
```
