
# 🐉 Dragon City Marketplace - Guía Completa de Despliegue

Esta guía te permitirá desplegar Dragon City Marketplace en tu VPS de manera profesional y segura.

## 📋 Requisitos del Sistema

- **Sistema Operativo**: Ubuntu 20.04 LTS o superior
- **RAM**: Mínimo 2GB (recomendado 4GB)
- **Almacenamiento**: Mínimo 20GB de espacio libre
- **Acceso**: Usuario con privilegios sudo
- **Dominio**: Dominio configurado apuntando a tu VPS (opcional pero recomendado)

## 🚀 Instalación Rápida (Automatizada)

### Paso 1: Clonar el Repositorio
```bash
git clone <tu-repositorio-url> /var/www/dragon-city-marketplace
cd /var/www/dragon-city-marketplace
```

### Paso 2: Ejecutar Scripts de Instalación
```bash
# Hacer ejecutables los scripts
chmod +x *.sh

# 1. Instalar dependencias del sistema
sudo ./install_deps.sh

# 2. Configurar base de datos
sudo ./setup_database.sh

# 3. Configurar Nginx
sudo ./nginx_config.sh

# 4. Desplegar aplicación
./deploy.sh
```

### Paso 3: Configurar Variables de Entorno
```bash
# Copiar archivo de ejemplo
cp .env.example app/.env

# Editar variables de entorno
nano app/.env
```

¡Listo! Tu aplicación estará disponible en tu dominio o IP del servidor.

---

## 📖 Instalación Manual Detallada

### 1. Preparación del Sistema

#### 1.1 Actualizar el Sistema
```bash
sudo apt update && sudo apt upgrade -y
```

#### 1.2 Instalar Node.js 18.x
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

#### 1.3 Instalar PostgreSQL
```bash
sudo apt install postgresql postgresql-contrib -y
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### 1.4 Instalar Nginx
```bash
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
```

#### 1.5 Instalar PM2 (Gestor de Procesos)
```bash
sudo npm install -g pm2
```

#### 1.6 Instalar Certbot (SSL)
```bash
sudo apt install certbot python3-certbot-nginx -y
```

### 2. Configuración de Base de Datos

#### 2.1 Crear Usuario y Base de Datos
```bash
sudo -u postgres psql
```

En el prompt de PostgreSQL:
```sql
CREATE USER dragonuser WITH PASSWORD 'tu_password_seguro';
CREATE DATABASE dragondb OWNER dragonuser;
GRANT ALL PRIVILEGES ON DATABASE dragondb TO dragonuser;
\q
```

#### 2.2 Configurar Acceso
```bash
# Editar configuración de PostgreSQL
sudo nano /etc/postgresql/*/main/pg_hba.conf

# Agregar esta línea antes de las otras reglas:
# local   dragondb        dragonuser                              md5

# Reiniciar PostgreSQL
sudo systemctl restart postgresql
```

### 3. Configuración de la Aplicación

#### 3.1 Clonar y Configurar
```bash
# Clonar en directorio web
sudo git clone <tu-repositorio-url> /var/www/dragon-city-marketplace
cd /var/www/dragon-city-marketplace

# Cambiar propietario
sudo chown -R $USER:$USER /var/www/dragon-city-marketplace
```

#### 3.2 Instalar Dependencias
```bash
npm install
cd app && npm install
```

#### 3.3 Configurar Variables de Entorno
```bash
cp .env.example app/.env
nano app/.env
```

Configurar las siguientes variables:
```env
# Base de Datos
DATABASE_URL="postgresql://dragonuser:tu_password_seguro@localhost:5432/dragondb"

# NextAuth
NEXTAUTH_URL="https://tu-dominio.com"
NEXTAUTH_SECRET="tu_secret_muy_seguro_de_32_caracteres_minimo"

# Google AdSense (opcional)
NEXT_PUBLIC_ADSENSE_CLIENT_ID="ca-pub-xxxxxxxxxxxxxxxx"

# Configuración de Producción
NODE_ENV="production"
```

#### 3.4 Configurar Base de Datos
```bash
cd app
npx prisma generate
npx prisma db push
```

#### 3.5 Construir Aplicación
```bash
npm run build
```

### 4. Configuración de Nginx

#### 4.1 Crear Configuración del Sitio
```bash
sudo nano /etc/nginx/sites-available/dragon-city-marketplace
```

Contenido del archivo:
```nginx
server {
    listen 80;
    server_name tu-dominio.com www.tu-dominio.com;

    # Redirigir HTTP a HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name tu-dominio.com www.tu-dominio.com;

    # Certificados SSL (se configurarán con Certbot)
    ssl_certificate /etc/letsencrypt/live/tu-dominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tu-dominio.com/privkey.pem;

    # Configuración SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

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
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Archivos estáticos
    location /_next/static {
        alias /var/www/dragon-city-marketplace/app/.next/static;
        expires 365d;
        access_log off;
    }

    # Imágenes y assets
    location /images {
        alias /var/www/dragon-city-marketplace/app/public/images;
        expires 30d;
        access_log off;
    }

    # Seguridad
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
```

#### 4.2 Habilitar Sitio
```bash
sudo ln -s /etc/nginx/sites-available/dragon-city-marketplace /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 5. Configuración de SSL

#### 5.1 Obtener Certificado SSL
```bash
sudo certbot --nginx -d tu-dominio.com -d www.tu-dominio.com
```

#### 5.2 Configurar Renovación Automática
```bash
sudo crontab -e
```

Agregar:
```bash
0 12 * * * /usr/bin/certbot renew --quiet
```

### 6. Configuración de PM2

#### 6.1 Crear Archivo de Configuración
```bash
nano ecosystem.config.js
```

#### 6.2 Iniciar con PM2
```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### 7. Configuración de Firewall

```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

### 8. Configuración de Logs

```bash
# Crear directorio de logs
sudo mkdir -p /var/log/dragon-city-marketplace
sudo chown $USER:$USER /var/log/dragon-city-marketplace

# Configurar rotación de logs
sudo nano /etc/logrotate.d/dragon-city-marketplace
```

Contenido:
```
/var/log/dragon-city-marketplace/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
}
```

---

## 🔄 Actualización y Mantenimiento

### Script de Actualización
```bash
./deploy.sh
```

### Comandos Útiles
```bash
# Ver logs de la aplicación
pm2 logs dragon-city-marketplace

# Reiniciar aplicación
pm2 restart dragon-city-marketplace

# Ver estado
pm2 status

# Monitorear recursos
pm2 monit

# Ver logs de Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

---

## 🛠️ Troubleshooting

### Problemas Comunes

#### 1. Error de Conexión a Base de Datos
```bash
# Verificar estado de PostgreSQL
sudo systemctl status postgresql

# Verificar conexión
psql -h localhost -U dragonuser -d dragondb

# Revisar logs
sudo tail -f /var/log/postgresql/postgresql-*.log
```

#### 2. Error 502 Bad Gateway
```bash
# Verificar que la aplicación esté corriendo
pm2 status

# Verificar configuración de Nginx
sudo nginx -t

# Revisar logs
pm2 logs dragon-city-marketplace
sudo tail -f /var/log/nginx/error.log
```

#### 3. Problemas de SSL
```bash
# Verificar certificados
sudo certbot certificates

# Renovar manualmente
sudo certbot renew

# Verificar configuración SSL
openssl s_client -connect tu-dominio.com:443
```

#### 4. Problemas de Permisos
```bash
# Corregir permisos
sudo chown -R $USER:$USER /var/www/dragon-city-marketplace
chmod -R 755 /var/www/dragon-city-marketplace
```

#### 5. Error de Memoria
```bash
# Verificar uso de memoria
free -h
pm2 monit

# Reiniciar aplicación si es necesario
pm2 restart dragon-city-marketplace
```

### Logs Importantes
- **Aplicación**: `pm2 logs dragon-city-marketplace`
- **Nginx**: `/var/log/nginx/error.log`
- **PostgreSQL**: `/var/log/postgresql/postgresql-*.log`
- **Sistema**: `journalctl -u nginx` o `journalctl -u postgresql`

### Comandos de Diagnóstico
```bash
# Verificar puertos abiertos
sudo netstat -tlnp

# Verificar procesos
ps aux | grep node
ps aux | grep nginx

# Verificar espacio en disco
df -h

# Verificar memoria
free -h

# Verificar carga del sistema
top
```

---

## 🔒 Seguridad Adicional

### 1. Configurar Fail2Ban
```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
```

### 2. Configurar Backup Automático
```bash
# Crear script de backup
nano /home/$USER/backup.sh
chmod +x /home/$USER/backup.sh

# Agregar a crontab
crontab -e
# 0 2 * * * /home/$USER/backup.sh
```

### 3. Monitoreo
```bash
# Instalar htop para monitoreo
sudo apt install htop -y

# Configurar alertas de espacio en disco
# (Agregar a crontab)
# 0 */6 * * * df -h | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }' | while read output; do echo $output; done
```

---

## 📞 Soporte

Si encuentras problemas durante el despliegue:

1. Revisa los logs mencionados en la sección de troubleshooting
2. Verifica que todos los servicios estén corriendo
3. Asegúrate de que las variables de entorno estén configuradas correctamente
4. Verifica la conectividad de red y DNS

---

## 📝 Notas Importantes

- **Backup**: Siempre realiza backups antes de actualizar
- **Seguridad**: Mantén el sistema actualizado regularmente
- **Monitoreo**: Revisa los logs periódicamente
- **Performance**: Monitorea el uso de recursos del servidor
- **SSL**: Los certificados se renuevan automáticamente cada 90 días

---

¡Tu Dragon City Marketplace está listo para funcionar! 🎉
