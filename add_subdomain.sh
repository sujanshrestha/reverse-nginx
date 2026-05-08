#!/bin/bash

# Script to add a new subdomain configuration for nginx reverse proxy with SSL
# Usage: ./add_subdomain.sh <subdomain> <service_name> [port]

if [ $# -lt 2 ]; then
    echo "Usage: $0 <subdomain> <service_name> [port]"
    echo "Example: $0 api.example.com myapi 3000"
    exit 1
fi

SUBDOMAIN=$1
SERVICE=$2
PORT=${3:-80}

CONF_FILE="config/conf.d/${SUBDOMAIN}.conf"
CERT_FILE="certs/${SUBDOMAIN}.pem"
KEY_FILE="certs/${SUBDOMAIN}-key.pem"

if [ -f "$CONF_FILE" ]; then
    echo "Configuration file $CONF_FILE already exists!"
    exit 1
fi

# Generate SSL certificate if not exists
if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "Generating SSL certificate for $SUBDOMAIN using mkcert..."
    mkcert -cert-file "$CERT_FILE" -key-file "$KEY_FILE" "$SUBDOMAIN"
    echo "Certificate generated: $CERT_FILE and $KEY_FILE"
else
    echo "SSL certificate already exists for $SUBDOMAIN"
fi

cat > "$CONF_FILE" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $SUBDOMAIN;

    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $SUBDOMAIN;

    ssl_certificate /etc/certs/${SUBDOMAIN}.pem;
    ssl_certificate_key /etc/certs/${SUBDOMAIN}-key.pem;

    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;

    location / {
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-NginX-Proxy true;
        proxy_pass http://$SERVICE:$PORT/;
        proxy_ssl_session_reuse off;
        proxy_set_header Host \$http_host;
        proxy_cache_bypass \$http_upgrade;
        proxy_redirect off;
    }

    # error section
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

echo "Created configuration file: $CONF_FILE"
echo "Don't forget to add the service '$SERVICE' to your docker-compose.yml if not already present."
echo "Also, ensure DNS points $SUBDOMAIN to this server."
echo "Restarting nginx..."
docker-compose restart reverse-nginx
echo "Nginx restarted. Changes applied."