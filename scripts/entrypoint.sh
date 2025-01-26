#!/bin/bash

set -e

# Default values
LE_EMAIL="${LE_EMAIL:-default@example.com}"
LE_HOST="${LE_HOST:-net-test1.example.com}"
CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-}"

# Replace placeholders in configs
echo "Replacing placeholders in configs..."
sed -i "s|LE_HOST_PLACEHOLDER|$LE_HOST|g" /etc/nginx/http.d/testsite.conf || echo "Failed to update NGINX config."
sed -i "s|LE_HOST_PLACEHOLDER|$LE_HOST|g" /etc/apache2/conf.d/testsite.conf || echo "Failed to update Apache config."
sed -i "s|CLOUDFLARE_API_TOKEN_PLACEHOLDER|$CLOUDFLARE_API_TOKEN|g" /etc/letsencrypt/cloudflare.ini || echo "Failed to update Cloudflare credentials."
sed -i 's/^Listen 80$/Listen 9443/' /etc/apache2/httpd.conf

# SSL generation with Cloudflare DNS validation
echo "Checking for SSL generation..."
if [ -n "$CLOUDFLARE_API_TOKEN" ] && [ "$LE_EMAIL" != "default@example.com" ]; then
    echo "Generating SSL certificates for $LE_HOST with email $LE_EMAIL using Cloudflare DNS..."
    if certbot certonly --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
        --dns-cloudflare-propagation-seconds 30 \
        --non-interactive --agree-tos -d "$LE_HOST" --email "$LE_EMAIL"; then
        echo "SSL certificates generated successfully for $LE_HOST."
    else
        echo "Failed to generate SSL certificates for $LE_HOST. Proceeding without SSL."
    fi
else
    echo "CLOUDFLARE_API_TOKEN or LE_EMAIL not provided. Skipping SSL generation."
    echo "Container will start with default configurations. Use /scripts/setup_ssl.sh to configure later."
fi

# Check if certificates exist
if [ ! -f "/etc/letsencrypt/live/$LE_HOST/fullchain.pem" ] || [ ! -f "/etc/letsencrypt/live/$LE_HOST/privkey.pem" ]; then
    echo "SSL certificates for $LE_HOST are missing. Starting without SSL."
    sed -i "s|SSLEngine on|# SSLEngine on|g" /etc/apache2/conf.d/testsite.conf
    sed -i "s|SSLCertificateFile.*|# SSLCertificateFile|g" /etc/apache2/conf.d/testsite.conf
    sed -i "s|SSLCertificateKeyFile.*|# SSLCertificateKeyFile|g" /etc/apache2/conf.d/testsite.conf
fi

# Always start Supervisor to manage services
echo "Starting NGINX and Apache with Supervisor..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
