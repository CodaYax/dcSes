
#!/bin/bash

# Dragon City Marketplace - Script de Configuración de Base de Datos
# Este script configura PostgreSQL y crea la base de datos necesaria

set -e

echo "🐉 Dragon City Marketplace - Configurando Base de Datos..."

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

# Variables de configuración
DB_NAME="dragondb"
DB_USER="dragonuser"
DB_PASSWORD=""

# Solicitar contraseña para la base de datos
while [[ -z "$DB_PASSWORD" ]]; do
    print_input "Ingresa una contraseña segura para el usuario de la base de datos:"
    read -s DB_PASSWORD
    echo ""
    if [[ ${#DB_PASSWORD} -lt 8 ]]; then
        print_error "La contraseña debe tener al menos 8 caracteres"
        DB_PASSWORD=""
    fi
done

print_status "Verificando estado de PostgreSQL..."
if ! systemctl is-active --quiet postgresql; then
    print_status "Iniciando PostgreSQL..."
    systemctl start postgresql
fi

print_status "Creando usuario y base de datos..."

# Crear usuario y base de datos
sudo -u postgres psql << EOF
-- Crear usuario si no existe
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN
        CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
    END IF;
END
\$\$;

-- Crear base de datos si no existe
SELECT 'CREATE DATABASE $DB_NAME OWNER $DB_USER'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME')\gexec

-- Otorgar privilegios
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
GRANT ALL ON SCHEMA public TO $DB_USER;

-- Mostrar información
\l
\du
EOF

print_status "Configurando acceso a la base de datos..."

# Backup del archivo de configuración
PG_VERSION=$(sudo -u postgres psql -t -c "SELECT version();" | grep -oP '\d+\.\d+' | head -1)
PG_CONFIG_DIR="/etc/postgresql/$PG_VERSION/main"
HBA_FILE="$PG_CONFIG_DIR/pg_hba.conf"

if [[ -f "$HBA_FILE" ]]; then
    print_status "Creando backup de pg_hba.conf..."
    cp "$HBA_FILE" "$HBA_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    
    print_status "Configurando autenticación para el usuario de la aplicación..."
    
    # Agregar regla de autenticación si no existe
    if ! grep -q "local.*$DB_NAME.*$DB_USER.*md5" "$HBA_FILE"; then
        sed -i "/^# Database administrative login by Unix domain socket/a local   $DB_NAME        $DB_USER                                md5" "$HBA_FILE"
        print_status "Regla de autenticación agregada"
    else
        print_warning "La regla de autenticación ya existe"
    fi
    
    print_status "Reiniciando PostgreSQL para aplicar cambios..."
    systemctl restart postgresql
    
    # Esperar a que PostgreSQL esté listo
    sleep 3
else
    print_error "No se encontró el archivo de configuración de PostgreSQL"
    exit 1
fi

print_status "Verificando conexión a la base de datos..."

# Verificar conexión
if PGPASSWORD="$DB_PASSWORD" psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    print_status "✅ Conexión a la base de datos exitosa"
else
    print_error "❌ Error al conectar a la base de datos"
    exit 1
fi

print_status "Configurando variables de entorno..."

# Crear archivo .env si no existe
ENV_FILE="/var/www/dragon-city-marketplace/app/.env"
if [[ ! -f "$ENV_FILE" ]]; then
    print_status "Creando archivo .env..."
    
    # Generar NEXTAUTH_SECRET
    NEXTAUTH_SECRET=$(openssl rand -base64 32)
    
    cat > "$ENV_FILE" << EOF
# Base de Datos
DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME"

# NextAuth
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="$NEXTAUTH_SECRET"

# Google AdSense (opcional - configurar después)
NEXT_PUBLIC_ADSENSE_CLIENT_ID=""

# Configuración de Producción
NODE_ENV="production"
EOF

    # Establecer permisos seguros
    chown www-data:www-data "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    
    print_status "Archivo .env creado con configuración básica"
else
    print_warning "El archivo .env ya existe, no se sobrescribirá"
fi

print_status "Configurando esquema de base de datos..."

# Cambiar al directorio de la aplicación
cd /var/www/dragon-city-marketplace/app

# Verificar si Prisma está instalado
if [[ ! -d "node_modules" ]]; then
    print_status "Instalando dependencias de la aplicación..."
    npm install
fi

print_status "Generando cliente de Prisma..."
npx prisma generate

print_status "Aplicando migraciones de base de datos..."
npx prisma db push

print_status "Verificando tablas creadas..."
PGPASSWORD="$DB_PASSWORD" psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "\dt"

print_status "✅ Configuración de base de datos completada exitosamente!"

echo ""
echo "📋 Información de la base de datos:"
echo "- Base de datos: $DB_NAME"
echo "- Usuario: $DB_USER"
echo "- Host: localhost"
echo "- Puerto: 5432"
echo ""
echo "🔐 Credenciales guardadas en: $ENV_FILE"
echo ""
print_warning "Siguiente paso: Ejecutar ./nginx_config.sh"
