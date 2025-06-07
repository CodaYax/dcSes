
#!/bin/bash

# Dragon City Marketplace - Script de Instalación de Dependencias
# Este script instala todas las dependencias necesarias para el sistema

set -e

echo "🐉 Dragon City Marketplace - Instalando Dependencias del Sistema..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Verificar si se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   print_error "Este script debe ejecutarse como root (usa sudo)"
   exit 1
fi

print_status "Actualizando repositorios del sistema..."
apt update -y

print_status "Actualizando paquetes del sistema..."
apt upgrade -y

print_status "Instalando herramientas básicas..."
apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release

print_status "Instalando Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

print_status "Verificando instalación de Node.js..."
node_version=$(node --version)
npm_version=$(npm --version)
print_status "Node.js instalado: $node_version"
print_status "NPM instalado: $npm_version"

print_status "Instalando PostgreSQL..."
apt install -y postgresql postgresql-contrib

print_status "Iniciando y habilitando PostgreSQL..."
systemctl start postgresql
systemctl enable postgresql

print_status "Instalando Nginx..."
apt install -y nginx

print_status "Iniciando y habilitando Nginx..."
systemctl start nginx
systemctl enable nginx

print_status "Instalando PM2 globalmente..."
npm install -g pm2

print_status "Instalando Certbot para SSL..."
apt install -y certbot python3-certbot-nginx

print_status "Instalando herramientas adicionales..."
apt install -y git htop ufw fail2ban logrotate

print_status "Configurando firewall básico..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 'Nginx Full'
ufw --force enable

print_status "Configurando Fail2Ban..."
systemctl enable fail2ban
systemctl start fail2ban

print_status "Limpiando paquetes innecesarios..."
apt autoremove -y
apt autoclean

print_status "Verificando servicios instalados..."
echo "PostgreSQL: $(systemctl is-active postgresql)"
echo "Nginx: $(systemctl is-active nginx)"
echo "Fail2Ban: $(systemctl is-active fail2ban)"

print_status "✅ Instalación de dependencias completada exitosamente!"
print_warning "Siguiente paso: Ejecutar ./setup_database.sh"

echo ""
echo "📋 Resumen de lo instalado:"
echo "- Node.js: $node_version"
echo "- NPM: $npm_version"
echo "- PostgreSQL: $(psql --version | head -n1)"
echo "- Nginx: $(nginx -v 2>&1)"
echo "- PM2: $(pm2 --version)"
echo "- Certbot: $(certbot --version | head -n1)"
echo ""
