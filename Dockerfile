FROM alpine:latest

ENV NGINX_PORT=8443
ENV APACHE_PORT=9443

RUN apk add --no-cache \
    tcpdump \
    nmap \
    curl \
    wget \
    net-tools \
    bind-tools \
    iputils \
    traceroute \
    nginx \
    apache2 \
    apache2-ssl \
    certbot \
    certbot-nginx \
    certbot-apache \
    certbot-dns-cloudflare \
    supervisor \
    bash \
    openssl

COPY public/index.html /var/www/localhost/htdocs/index.html

RUN mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
COPY config/testsite.conf /etc/nginx/http.d/testsite.conf
COPY config/apache.conf /etc/apache2/conf.d/testsite.conf
COPY config/cloudflare.ini /etc/letsencrypt/cloudflare.ini
RUN chmod 600 /etc/letsencrypt/cloudflare.ini
COPY config/supervisord.conf /etc/supervisord.conf

COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8443 9443

CMD ["/entrypoint.sh"]
