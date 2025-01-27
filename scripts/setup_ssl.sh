#!/bin/bash

set -e

# Prompt for variables securely
read -p "Enter Let's Encrypt Email: " LE_EMAIL
read -p "Enter Host Domain for Let's Encrypt: " LE_HOST
read -sp "Enter Cloudflare API Token: " CLOUDFLARE_API_TOKEN
echo ""

# Validate inputs
if [[ -z "$LE_EMAIL" || -z "$LE_HOST" || -z "$CLOUDFLARE_API_TOKEN" ]]; then
    echo "Error: All inputs (LE_EMAIL, LE_HOST, CLOUDFLARE_API_TOKEN) are required."
    exit 1
fi

# Export variables for the session
export LE_EMAIL="$LE_EMAIL"
export LE_HOST="$LE_HOST"
export CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_TOKEN"

# Replace placeholders in configuration files
echo "Replacing placeholders in configs..."
sed -i "s|LE_HOST_PLACEHOLDER|$LE_HOST|g" /etc/nginx/http.d/testsite.conf || echo "Failed to update NGINX config."
sed -i "s|LE_HOST_PLACEHOLDER|$LE_HOST|g" /etc/apache2/conf.d/testsite.conf || echo "Failed to update Apache config."
sed -i "s|CLOUDFLARE_API_TOKEN_PLACEHOLDER|$CLOUDFLARE_API_TOKEN|g" /etc/letsencrypt/cloudflare.ini || echo "Failed to update Cloudflare credentials."
sed -i 's/^Listen 80$/Listen 9443/' /etc/apache2/httpd.conf

# Rebuild SSL configuration in Apache file
echo "Rebuilding SSL directives in Apache configuration..."
sed -i "s|# SSLEngine on|SSLEngine on|g" /etc/apache2/conf.d/testsite.conf
sed -i "s|# SSLCertificateFile.*|SSLCertificateFile /etc/letsencrypt/live/$LE_HOST/fullchain.pem|g" /etc/apache2/conf.d/testsite.conf
sed -i "s|# SSLCertificateKeyFile.*|SSLCertificateKeyFile /etc/letsencrypt/live/$LE_HOST/privkey.pem|g" /etc/apache2/conf.d/testsite.conf

# Generate SSL certificates using Certbot
echo "Generating SSL certificates for $LE_HOST..."
if certbot certonly --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
    --dns-cloudflare-propagation-seconds 30 \
    --non-interactive --agree-tos -d "$LE_HOST" --email "$LE_EMAIL"; then
    echo "SSL certificates generated successfully for $LE_HOST."
else
    echo "Failed to generate SSL certificates for $LE_HOST."
fi

# Validate that SSL certificates were successfully created
if [ ! -f "/etc/letsencrypt/live/$LE_HOST/fullchain.pem" ] || [ ! -f "/etc/letsencrypt/live/$LE_HOST/privkey.pem" ]; then
    echo "SSL certificates for $LE_HOST are missing. Disabling SSL in Apache configuration."
    sed -i "s|SSLEngine on|# SSLEngine on|g" /etc/apache2/conf.d/testsite.conf
    sed -i "s|SSLCertificateFile.*|# SSLCertificateFile|g" /etc/apache2/conf.d/testsite.conf
    sed -i "s|SSLCertificateKeyFile.*|# SSLCertificateKeyFile|g" /etc/apache2/conf.d/testsite.conf
else
    echo "SSL certificates are in place and Apache is configured to use them."
fi

# Restart services
echo "Restarting services..."
supervisorctl restart nginx apache || echo "Failed to restart services. Check Supervisor configuration."

echo "Manual SSL setup and service restart completed successfully."
