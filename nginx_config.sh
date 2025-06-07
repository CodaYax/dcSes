
#!/bin/bash

# Dragon City Marketplace - Script de Configuración de Nginx
# Este script configura Nginx como proxy reverso para la aplicación

set -e

echo "🐉 Dragon City Marketplace - Configurando Nginx..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_input() {
    echo -e "${BLUE}[INPUT]${NC} $1"
}

# Verificar si se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   print_error "Este script debe ejecutarse como root (usa sudo)"
   exit 1
fi

# Variables
SITE_NAME="dragon-city-marketplace"
NGINX_AVAILABLE="/etc/nginx/sites-available/$SITE_NAME"
NGINX_ENABLED="/etc/nginx/sites-enabled/$SITE_NAME"
APP_DIR="/var/www/dragon-city-marketplace"

# Solicitar dominio
print_input "Ingresa tu dominio (ejemplo: midominio.com) o presiona Enter para usar localhost:"
read DOMAIN

if [[ -z "$DOMAIN" ]]; then
    DOMAIN="localhost"
    SERVER_NAME="localhost"
    print_warning "Usando configuración para localhost"
else
    SERVER_NAME="$DOMAIN www.$DOMAIN"
    print_status "Configurando para dominio: $DOMAIN"
fi

print_status "Verificando que Nginx esté instalado..."
if ! command -v nginx &> /dev/null; then
    print_error "Nginx no está instalado. Ejecuta primero install_deps.sh"
    exit 1
fi

print_status "Creando configuración de Nginx..."

# Crear configuración de Nginx
cat > "$NGINX_AVAILABLE" << EOF
# Dragon City Marketplace - Configuración de Nginx
server {
    listen 80;
    server_name $SERVER_NAME;

    # Redirigir a HTTPS si no es localhost
    $(if [[ "$DOMAIN" != "localhost" ]]; then echo "return 301 https://\$server_name\$request_uri;"; fi)
    
    $(if [[ "$DOMAIN" == "localhost" ]]; then cat << 'LOCALHOST_CONFIG'
    # Configuración para localhost (desarrollo/testing)
    
    # Compresión
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript;

    # Proxy a la aplicación Next.js
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Archivos estáticos
    location /_next/static {
        alias $APP_DIR/app/.next/static;
        expires 365d;
        access_log off;
    }

    # Imágenes y assets
    location /images {
        alias $APP_DIR/app/public/images;
        expires 30d;
        access_log off;
    }
LOCALHOST_CONFIG
fi)
}

$(if [[ "$DOMAIN" != "localhost" ]]; then cat << 'HTTPS_CONFIG'
server {
    listen 443 ssl http2;
    server_name $SERVER_NAME;

    # Certificados SSL (se configurarán con Certbot)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # Configuración SSL moderna
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Compresión
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript;

    # Proxy a la aplicación Next.js
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Archivos estáticos
    location /_next/static {
        alias $APP_DIR/app/.next/static;
        expires 365d;
        access_log off;
    }

    # Imágenes y assets
    location /images {
        alias $APP_DIR/app/public/images;
        expires 30d;
        access_log off;
    }

    # Seguridad
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline' *.googletagservices.com *.googlesyndication.com *.google.com" always;
}
HTTPS_CONFIG
fi)
EOF

print_status "Deshabilitando sitio por defecto de Nginx..."
if [[ -L "/etc/nginx/sites-enabled/default" ]]; then
    rm -f /etc/nginx/sites-enabled/default
fi

print_status "Habilitando sitio de Dragon City Marketplace..."
if [[ -L "$NGINX_ENABLED" ]]; then
    rm -f "$NGINX_ENABLED"
fi
ln -s "$NGINX_AVAILABLE" "$NGINX_ENABLED"

print_status "Verificando configuración de Nginx..."
if nginx -t; then
    print_status "✅ Configuración de Nginx válida"
else
    print_error "❌ Error en la configuración de Nginx"
    exit 1
fi

print_status "Reiniciando Nginx..."
systemctl restart nginx

print_status "Verificando estado de Nginx..."
if systemctl is-active --quiet nginx; then
    print_status "✅ Nginx está funcionando correctamente"
else
    print_error "❌ Error: Nginx no está funcionando"
    systemctl status nginx
    exit 1
fi

# Configurar SSL si no es localhost
if [[ "$DOMAIN" != "localhost" ]]; then
    print_status "Configurando SSL con Certbot..."
    print_warning "Asegúrate de que tu dominio apunte a este servidor antes de continuar"
    
    print_input "¿Deseas configurar SSL ahora? (y/n):"
    read -r SETUP_SSL
    
    if [[ "$SETUP_SSL" =~ ^[Yy]$ ]]; then
        print_status "Obteniendo certificado SSL..."
        if certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --email admin@"$DOMAIN"; then
            print_status "✅ SSL configurado exitosamente"
            
            # Configurar renovación automática
            print_status "Configurando renovación automática de SSL..."
            (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
            
        else
            print_warning "No se pudo configurar SSL automáticamente"
            print_status "Puedes configurarlo manualmente más tarde con:"
            print_status "sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
        fi
    else
        print_warning "SSL no configurado. Puedes configurarlo más tarde con:"
        print_status "sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
    fi
fi

# Actualizar NEXTAUTH_URL en .env si existe
ENV_FILE="$APP_DIR/app/.env"
if [[ -f "$ENV_FILE" ]]; then
    print_status "Actualizando NEXTAUTH_URL en .env..."
    if [[ "$DOMAIN" == "localhost" ]]; then
        NEW_URL="http://localhost"
    else
        NEW_URL="https://$DOMAIN"
    fi
    
    if grep -q "NEXTAUTH_URL=" "$ENV_FILE"; then
        sed -i "s|NEXTAUTH_URL=.*|NEXTAUTH_URL=\"$NEW_URL\"|" "$ENV_FILE"
    else
        echo "NEXTAUTH_URL=\"$NEW_URL\"" >> "$ENV_FILE"
    fi
    print_status "NEXTAUTH_URL actualizado a: $NEW_URL"
fi

print_status "✅ Configuración de Nginx completada exitosamente!"

echo ""
echo "📋 Información de la configuración:"
echo "- Sitio: $SITE_NAME"
echo "- Dominio: $DOMAIN"
echo "- Configuración: $NGINX_AVAILABLE"
echo "- Puerto HTTP: 80"
if [[ "$DOMAIN" != "localhost" ]]; then
    echo "- Puerto HTTPS: 443"
    echo "- SSL: $(if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then echo "Configurado"; else echo "Pendiente"; fi)"
fi
echo ""

if [[ "$DOMAIN" == "localhost" ]]; then
    print_status "🌐 Tu aplicación estará disponible en: http://localhost"
else
    print_status "🌐 Tu aplicación estará disponible en: https://$DOMAIN"
fi

print_warning "Siguiente paso: Ejecutar ./deploy.sh"
