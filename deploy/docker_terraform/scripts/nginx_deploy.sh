#!/bin/bash

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <IP1> <IP2> <IP3>"
  exit 1
fi

IP1=$1
IP2=$2
IP3=$3

cat <<EOF > /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 4096;
    multi_accept on;
    use epoll;  # Sur Linux uniquement
}

http {
    upstream backend {
        least_conn;
        server 127.0.0.1:5000;
        server $IP2:5000;
        server $IP3:5000;
        keepalive 32;
    }

    upstream frontend {
        least_conn;
        server 127.0.0.1:3000;
        server $IP2:3000;
        server $IP3:3000;
        keepalive 32;
    }

    server {
        listen 80;

        # API backend
        location /api/ {
            # Supprimer le /api avant d'envoyer au backend
            rewrite ^/api(/.*)$ \$1 break;
            proxy_pass http://backend;

            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection '';
            proxy_set_header Host \$host;
            proxy_cache_bypass \$http_upgrade;

            proxy_connect_timeout 5s;
            proxy_send_timeout 10s;
            proxy_read_timeout 10s;
            send_timeout 10s;
        }

        # Frontend React (index.html, JS, etc.)
        location / {
            proxy_pass http://frontend;

            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection '';
            proxy_set_header Host \$host;
            proxy_cache_bypass \$http_upgrade;

            proxy_connect_timeout 5s;
            proxy_send_timeout 10s;
            proxy_read_timeout 10s;
            send_timeout 10s;
        }

    }
}
EOF

echo "Nginx configuration file written to /etc/nginx/nginx.conf"

echo "Reloading nginx..."
nginx -t && systemctl reload nginx
