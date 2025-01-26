#!/bin/bash

set -e

read -p "Enter Let's Encrypt Email: " LE_EMAIL
read -p "Enter Host Domain for Let's Encrypt: " LE_HOST

export LE_EMAIL="$LE_EMAIL"
export LE_HOST="$LE_HOST"

sed -i "s/LE_EMAIL_PLACEHOLDER/$LE_EMAIL/g" /etc/nginx/http.d/testsite.conf
sed -i "s/LE_HOST_PLACEHOLDER/$LE_HOST/g" /etc/nginx/http.d/testsite.conf
sed -i "s/LE_EMAIL_PLACEHOLDER/$LE_EMAIL/g" /etc/apache2/conf.d/testsite.conf
sed -i "s/LE_HOST_PLACEHOLDER/$LE_HOST/g" /etc/apache2/conf.d/testsite.conf

certbot certonly --standalone --non-interactive --agree-tos --email "$LE_EMAIL" -d "$LE_HOST"

supervisorctl restart nginx apache
echo "SSL setup complete for $LE_HOST."
