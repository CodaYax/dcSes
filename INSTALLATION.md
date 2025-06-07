
# Guía de Instalación - Dragon City Marketplace

Esta guía te ayudará a instalar y configurar Dragon City Marketplace en tu propio servidor o hosting.

## 📋 Requisitos del Sistema

### Mínimos
- **Node.js**: 18.0 o superior
- **PostgreSQL**: 12.0 o superior
- **RAM**: 1GB mínimo (2GB recomendado)
- **Almacenamiento**: 5GB mínimo
- **Ancho de banda**: Ilimitado recomendado

### Recomendados para Producción
- **CPU**: 2 cores o más
- **RAM**: 4GB o más
- **SSD**: Para mejor rendimiento
- **CDN**: Para servir imágenes estáticas

## 🚀 Instalación Paso a Paso

### 1. Preparación del Servidor

#### Ubuntu/Debian
```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Instalar PostgreSQL
sudo apt install postgresql postgresql-contrib

# Instalar PM2 para gestión de procesos
sudo npm install -g pm2

# Instalar Yarn (opcional)
sudo npm install -g yarn
```

#### CentOS/RHEL
```bash
# Actualizar sistema
sudo yum update -y

# Instalar Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Instalar PostgreSQL
sudo yum install postgresql-server postgresql-contrib
sudo postgresql-setup initdb
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Instalar PM2
sudo npm install -g pm2
```

### 2. Configuración de PostgreSQL

```bash
# Acceder a PostgreSQL
sudo -u postgres psql

# Crear base de datos y usuario
CREATE DATABASE dragon_city_marketplace;
CREATE USER dragon_user WITH ENCRYPTED PASSWORD 'tu_contraseña_segura';
GRANT ALL PRIVILEGES ON DATABASE dragon_city_marketplace TO dragon_user;
\q
```

### 3. Descargar y Configurar la Aplicación

```bash
# Clonar repositorio (reemplaza con tu URL)
git clone https://github.com/tu-usuario/dragon-city-marketplace.git
cd dragon-city-marketplace/app

# Instalar dependencias
npm install
# o si usas yarn
yarn install
```

### 4. Configuración de Variables de Entorno

```bash
# Crear archivo de configuración
cp .env.example .env

# Editar configuración
nano .env
```

Configurar las siguientes variables:

```env
# Base de datos
DATABASE_URL="postgresql://dragon_user:tu_contraseña_segura@localhost:5432/dragon_city_marketplace"

# Autenticación (generar secret seguro)
NEXTAUTH_SECRET="tu_secret_muy_seguro_aqui_32_caracteres_minimo"
NEXTAUTH_URL="https://tu-dominio.com"

# Configuraciones opcionales
UPLOAD_MAX_SIZE="10485760"  # 10MB
NODE_ENV="production"
```

### 5. Configurar Base de Datos

```bash
# Generar cliente Prisma
npx prisma generate

# Aplicar esquema a la base de datos
npx prisma db push

# Verificar conexión
npx prisma db pull
```

### 6. Crear Directorios de Uploads

```bash
# Crear directorios para imágenes
mkdir -p public/uploads/accounts
mkdir -p public/uploads/orbs
mkdir -p public/uploads/offers

# Configurar permisos
chmod 755 public/uploads
chmod 755 public/uploads/*
```

### 7. Construir para Producción

```bash
# Construir aplicación
npm run build

# Verificar que no hay errores
npm run start
```

### 8. Configurar PM2

```bash
# Crear archivo de configuración PM2
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'dragon-city-marketplace',
    script: 'npm',
    args: 'start',
    cwd: '/ruta/completa/a/dragon-city-marketplace/app',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
}
EOF

# Crear directorio de logs
mkdir logs

# Iniciar aplicación
pm2 start ecosystem.config.js

# Configurar inicio automático
pm2 save
pm2 startup
```

### 9. Configurar Nginx (Proxy Reverso)

```bash
# Instalar Nginx
sudo apt install nginx

# Crear configuración
sudo nano /etc/nginx/sites-available/dragon-city-marketplace
```

Configuración de Nginx:

```nginx
server {
    listen 80;
    server_name tu-dominio.com www.tu-dominio.com;

    # Redirigir a HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name tu-dominio.com www.tu-dominio.com;

    # Certificados SSL (configurar con Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/tu-dominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tu-dominio.com/privkey.pem;

    # Configuración SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Configuración de archivos estáticos
    location /_next/static/ {
        alias /ruta/completa/a/dragon-city-marketplace/app/.next/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /uploads/ {
        alias /ruta/completa/a/dragon-city-marketplace/app/public/uploads/;
        expires 1y;
        add_header Cache-Control "public";
    }

    # Proxy a Next.js
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Configuración de seguridad
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
```

```bash
# Habilitar sitio
sudo ln -s /etc/nginx/sites-available/dragon-city-marketplace /etc/nginx/sites-enabled/

# Verificar configuración
sudo nginx -t

# Reiniciar Nginx
sudo systemctl restart nginx
```

### 10. Configurar SSL con Let's Encrypt

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx

# Obtener certificado
sudo certbot --nginx -d tu-dominio.com -d www.tu-dominio.com

# Configurar renovación automática
sudo crontab -e
# Agregar línea:
0 12 * * * /usr/bin/certbot renew --quiet
```

### 11. Configurar Firewall

```bash
# Configurar UFW
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

### 12. Crear Usuario Administrador

```bash
# Acceder a la base de datos
sudo -u postgres psql dragon_city_marketplace

# Crear usuario admin (reemplaza con tus datos)
INSERT INTO users (id, email, name, password, "isAdmin", "isVerified", "createdAt", "updatedAt") 
VALUES (
  'admin-id-unique', 
  'admin@tu-dominio.com', 
  'Administrador', 
  '$2a$12$hash_de_contraseña_aqui', 
  true, 
  true, 
  NOW(), 
  NOW()
);
```

Para generar el hash de contraseña:
```bash
node -e "console.log(require('bcryptjs').hashSync('tu_contraseña_admin', 12))"
```

## 🔧 Configuraciones Adicionales

### Backup Automático

```bash
# Crear script de backup
cat > /home/dragon/backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/dragon/backups"
mkdir -p $BACKUP_DIR

# Backup de base de datos
pg_dump -U dragon_user -h localhost dragon_city_marketplace > $BACKUP_DIR/db_$DATE.sql

# Backup de uploads
tar -czf $BACKUP_DIR/uploads_$DATE.tar.gz -C /ruta/a/dragon-city-marketplace/app/public uploads

# Limpiar backups antiguos (mantener 7 días)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
EOF

chmod +x /home/dragon/backup.sh

# Programar backup diario
crontab -e
# Agregar:
0 2 * * * /home/dragon/backup.sh
```

### Monitoreo

```bash
# Instalar htop para monitoreo
sudo apt install htop

# Ver logs de la aplicación
pm2 logs dragon-city-marketplace

# Monitorear recursos
pm2 monit
```

### Optimizaciones de Rendimiento

```bash
# Configurar swap (si es necesario)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## 🚨 Solución de Problemas

### Error de Conexión a Base de Datos
```bash
# Verificar estado de PostgreSQL
sudo systemctl status postgresql

# Verificar conexión
sudo -u postgres psql -c "SELECT version();"

# Revisar logs
sudo tail -f /var/log/postgresql/postgresql-*.log
```

### Error de Permisos de Archivos
```bash
# Verificar permisos
ls -la public/uploads/

# Corregir permisos
sudo chown -R $USER:$USER public/uploads/
chmod -R 755 public/uploads/
```

### Aplicación No Inicia
```bash
# Verificar logs de PM2
pm2 logs dragon-city-marketplace

# Reiniciar aplicación
pm2 restart dragon-city-marketplace

# Verificar puerto
sudo netstat -tlnp | grep :3000
```

### Problemas de SSL
```bash
# Verificar certificados
sudo certbot certificates

# Renovar manualmente
sudo certbot renew

# Verificar configuración Nginx
sudo nginx -t
```

## 📞 Soporte

Si encuentras problemas durante la instalación:

1. **Revisa los logs**: `pm2 logs`, `/var/log/nginx/error.log`
2. **Verifica configuraciones**: Variables de entorno, permisos
3. **Consulta documentación**: README.md para más detalles
4. **Crea un issue**: En el repositorio con detalles del error

## 🔄 Actualizaciones

Para actualizar la aplicación:

```bash
# Hacer backup
./backup.sh

# Actualizar código
git pull origin main

# Instalar nuevas dependencias
npm install

# Aplicar migraciones de DB
npx prisma db push

# Reconstruir
npm run build

# Reiniciar aplicación
pm2 restart dragon-city-marketplace
```

---

¡Felicidades! Tu marketplace de Dragon City está listo para usar. 🎉
