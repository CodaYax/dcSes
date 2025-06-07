
#!/bin/bash

# Dragon City Marketplace - Script de Despliegue
# Este script despliega o actualiza la aplicación

set -e

echo "🐉 Dragon City Marketplace - Desplegando Aplicación..."

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

# Variables
APP_DIR="/var/www/dragon-city-marketplace"
APP_NAME="dragon-city-marketplace"
USER=$(whoami)

# Verificar que no se ejecute como root
if [[ $EUID -eq 0 ]]; then
   print_error "Este script NO debe ejecutarse como root"
   exit 1
fi

# Verificar que el directorio existe
if [[ ! -d "$APP_DIR" ]]; then
    print_error "Directorio de la aplicación no encontrado: $APP_DIR"
    exit 1
fi

cd "$APP_DIR"

print_status "Verificando repositorio Git..."
if [[ -d ".git" ]]; then
    print_status "Actualizando código desde repositorio..."
    git fetch origin
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || print_warning "No se pudo actualizar desde Git"
else
    print_warning "No es un repositorio Git, saltando actualización"
fi

print_status "Instalando dependencias del proyecto..."
npm install --production=false

print_status "Cambiando al directorio de la aplicación..."
cd app

print_status "Instalando dependencias de la aplicación..."
npm install --production=false

print_status "Verificando archivo .env..."
if [[ ! -f ".env" ]]; then
    print_error "Archivo .env no encontrado. Ejecuta primero setup_database.sh"
    exit 1
fi

print_status "Generando cliente de Prisma..."
npx prisma generate

print_status "Aplicando migraciones de base de datos..."
npx prisma db push

print_status "Construyendo aplicación para producción..."
npm run build

print_status "Verificando configuración de PM2..."
if ! command -v pm2 &> /dev/null; then
    print_error "PM2 no está instalado. Ejecuta primero install_deps.sh"
    exit 1
fi

# Verificar si la aplicación ya está corriendo
if pm2 list | grep -q "$APP_NAME"; then
    print_status "Reiniciando aplicación existente..."
    pm2 restart "$APP_NAME"
    pm2 reload "$APP_NAME"
else
    print_status "Iniciando aplicación por primera vez..."
    cd "$APP_DIR"
    pm2 start ecosystem.config.js
fi

print_status "Guardando configuración de PM2..."
pm2 save

print_status "Verificando estado de la aplicación..."
sleep 3
pm2 status

# Verificar que la aplicación responda
print_status "Verificando que la aplicación responda..."
for i in {1..10}; do
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        print_status "✅ Aplicación respondiendo correctamente"
        break
    else
        if [[ $i -eq 10 ]]; then
            print_error "❌ La aplicación no responde después de 10 intentos"
            print_status "Revisando logs..."
            pm2 logs "$APP_NAME" --lines 20
            exit 1
        fi
        print_warning "Intento $i/10: Esperando que la aplicación inicie..."
        sleep 3
    fi
done

print_status "Verificando servicios relacionados..."
echo "Nginx: $(systemctl is-active nginx 2>/dev/null || echo 'no instalado')"
echo "PostgreSQL: $(systemctl is-active postgresql 2>/dev/null || echo 'no instalado')"

print_status "✅ Despliegue completado exitosamente!"

echo ""
echo "📋 Información del despliegue:"
echo "- Aplicación: $APP_NAME"
echo "- Directorio: $APP_DIR"
echo "- Puerto local: 3000"
echo "- Estado PM2: $(pm2 list | grep "$APP_NAME" | awk '{print $10}' || echo 'unknown')"
echo ""
echo "🔧 Comandos útiles:"
echo "- Ver logs: pm2 logs $APP_NAME"
echo "- Reiniciar: pm2 restart $APP_NAME"
echo "- Estado: pm2 status"
echo "- Monitoreo: pm2 monit"
echo ""

# Mostrar información de acceso
if systemctl is-active --quiet nginx; then
    print_status "🌐 La aplicación está disponible a través de Nginx"
    print_status "Verifica tu configuración de dominio en /etc/nginx/sites-available/"
else
    print_warning "Nginx no está activo. La aplicación solo está disponible en http://localhost:3000"
fi

print_status "🎉 ¡Dragon City Marketplace está funcionando!"
