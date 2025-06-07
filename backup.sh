
#!/bin/bash

# Dragon City Marketplace - Script de Backup
# Este script crea backups de la base de datos y archivos de la aplicación

set -e

echo "🐉 Dragon City Marketplace - Creando Backup..."

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

# Variables de configuración
APP_DIR="/var/www/dragon-city-marketplace"
BACKUP_DIR="/home/$(whoami)/backups/dragon-city-marketplace"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="dragondb"
DB_USER="dragonuser"

# Crear directorio de backup si no existe
mkdir -p "$BACKUP_DIR"

print_status "Iniciando backup - $DATE"

# Leer configuración de .env
if [[ -f "$APP_DIR/app/.env" ]]; then
    source "$APP_DIR/app/.env"
    print_status "Configuración cargada desde .env"
else
    print_error "Archivo .env no encontrado"
    exit 1
fi

# Backup de base de datos
print_status "Creando backup de base de datos..."
DB_BACKUP_FILE="$BACKUP_DIR/database_$DATE.sql"

if PGPASSWORD=$(echo "$DATABASE_URL" | grep -oP '://[^:]+:\K[^@]+') pg_dump -h localhost -U "$DB_USER" -d "$DB_NAME" > "$DB_BACKUP_FILE"; then
    print_status "✅ Backup de base de datos creado: $DB_BACKUP_FILE"
    
    # Comprimir backup de DB
    gzip "$DB_BACKUP_FILE"
    print_status "Backup de base de datos comprimido"
else
    print_error "❌ Error al crear backup de base de datos"
    exit 1
fi

# Backup de archivos de la aplicación
print_status "Creando backup de archivos de aplicación..."
APP_BACKUP_FILE="$BACKUP_DIR/app_files_$DATE.tar.gz"

# Excluir directorios innecesarios
tar -czf "$APP_BACKUP_FILE" \
    --exclude="node_modules" \
    --exclude=".next" \
    --exclude=".git" \
    --exclude="logs" \
    --exclude="*.log" \
    -C "$(dirname "$APP_DIR")" \
    "$(basename "$APP_DIR")"

if [[ $? -eq 0 ]]; then
    print_status "✅ Backup de archivos creado: $APP_BACKUP_FILE"
else
    print_error "❌ Error al crear backup de archivos"
    exit 1
fi

# Backup de configuración de Nginx
print_status "Creando backup de configuración de Nginx..."
NGINX_BACKUP_FILE="$BACKUP_DIR/nginx_config_$DATE.tar.gz"

tar -czf "$NGINX_BACKUP_FILE" \
    /etc/nginx/sites-available/dragon-city-marketplace \
    /etc/nginx/sites-enabled/dragon-city-marketplace \
    2>/dev/null || print_warning "Algunas configuraciones de Nginx no se pudieron respaldar"

# Backup de configuración de PM2
print_status "Creando backup de configuración de PM2..."
PM2_BACKUP_FILE="$BACKUP_DIR/pm2_config_$DATE.json"
pm2 save --force
cp ~/.pm2/dump.pm2 "$PM2_BACKUP_FILE" 2>/dev/null || print_warning "No se pudo respaldar configuración de PM2"

# Limpiar backups antiguos (mantener solo los últimos 30 días)
print_status "Limpiando backups antiguos..."
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +30 -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "*.json" -mtime +30 -delete 2>/dev/null || true

# Mostrar resumen
print_status "✅ Backup completado exitosamente!"

echo ""
echo "📋 Resumen del backup:"
echo "- Fecha: $DATE"
echo "- Base de datos: $(basename "$DB_BACKUP_FILE").gz"
echo "- Archivos: $(basename "$APP_BACKUP_FILE")"
echo "- Nginx: $(basename "$NGINX_BACKUP_FILE")"
echo "- PM2: $(basename "$PM2_BACKUP_FILE")"
echo "- Ubicación: $BACKUP_DIR"
echo ""

# Mostrar tamaño de archivos
print_status "Tamaños de backup:"
ls -lh "$BACKUP_DIR"/*_"$DATE"* 2>/dev/null || true

print_status "🎉 Backup completado - Todos los datos están seguros!"
