# ✅ Dragon City Marketplace - Checklist Post-Despliegue

## Verificación Inmediata

### Servicios del Sistema
- [ ] PostgreSQL está corriendo: `sudo systemctl status postgresql`
- [ ] Nginx está corriendo: `sudo systemctl status nginx`
- [ ] Firewall configurado: `sudo ufw status`
- [ ] Fail2Ban activo: `sudo systemctl status fail2ban`

### Aplicación
- [ ] PM2 muestra la app corriendo: `pm2 status`
- [ ] Aplicación responde en localhost:3000: `curl http://localhost:3000`
- [ ] Base de datos conecta: `cd app && npx prisma db push`
- [ ] Logs sin errores críticos: `pm2 logs dragon-city-marketplace`

### Configuración Web
- [ ] Nginx proxy funciona: `curl http://tu-dominio.com` o `curl http://localhost`
- [ ] SSL configurado (si aplica): `curl https://tu-dominio.com`
- [ ] Archivos estáticos se sirven correctamente
- [ ] Compresión gzip activa: `curl -H "Accept-Encoding: gzip" -I http://tu-dominio.com`

## Verificación de Seguridad

### SSL/TLS (Solo para dominios públicos)
- [ ] Certificado SSL válido: `openssl s_client -connect tu-dominio.com:443`
- [ ] Renovación automática configurada: `sudo crontab -l | grep certbot`
- [ ] Headers de seguridad presentes: `curl -I https://tu-dominio.com`

### Base de Datos
- [ ] Usuario de DB con permisos limitados
- [ ] Contraseña segura configurada
- [ ] Conexiones externas bloqueadas (solo localhost)
- [ ] Backup automático configurado

### Archivos y Permisos
- [ ] Archivo .env con permisos 600: `ls -la app/.env`
- [ ] Directorio de aplicación con propietario correcto
- [ ] Logs escribibles: `ls -la /var/log/dragon-city-marketplace/`

## Verificación Funcional

### Funcionalidades Principales
- [ ] Página principal carga correctamente
- [ ] Registro de usuarios funciona
- [ ] Login de usuarios funciona
- [ ] Creación de listings funciona
- [ ] Panel de administración accesible
- [ ] Google AdSense se muestra (si configurado)

### Performance
- [ ] Tiempo de respuesta < 2 segundos
- [ ] Imágenes se cargan correctamente
- [ ] CSS y JS se cargan sin errores
- [ ] No hay errores 404 en recursos

## Monitoreo y Mantenimiento

### Logs
- [ ] Logs de aplicación: `tail -f /var/log/dragon-city-marketplace/combined.log`
- [ ] Logs de Nginx: `sudo tail -f /var/log/nginx/access.log`
- [ ] Logs de PostgreSQL: `sudo tail -f /var/log/postgresql/postgresql-*.log`

### Backup
- [ ] Script de backup funciona: `./backup.sh`
- [ ] Backup automático configurado en crontab
- [ ] Ubicación de backups accesible: `ls -la ~/backups/dragon-city-marketplace/`

### Actualizaciones
- [ ] Script de deploy funciona: `./deploy.sh`
- [ ] PM2 configurado para auto-restart
- [ ] Proceso de actualización documentado

## Configuración Adicional Recomendada

### Monitoreo
- [ ] Configurar alertas de espacio en disco
- [ ] Configurar monitoreo de memoria
- [ ] Configurar alertas de uptime

### Optimización
- [ ] Configurar cache de Nginx para archivos estáticos
- [ ] Optimizar configuración de PostgreSQL
- [ ] Configurar compresión de imágenes

### Backup Avanzado
- [ ] Backup remoto configurado
- [ ] Prueba de restauración realizada
- [ ] Documentación de procedimientos de recuperación

## Comandos de Verificación Rápida

```bash
# Verificación completa del sistema
echo "=== SERVICIOS ==="
sudo systemctl status postgresql nginx fail2ban --no-pager

echo "=== APLICACIÓN ==="
pm2 status
curl -I http://localhost:3000

echo "=== LOGS RECIENTES ==="
pm2 logs dragon-city-marketplace --lines 5

echo "=== ESPACIO EN DISCO ==="
df -h

echo "=== MEMORIA ==="
free -h

echo "=== PROCESOS ==="
ps aux | grep -E "(node|nginx|postgres)" | grep -v grep
```

## Solución de Problemas Comunes

### Si la aplicación no responde:
```bash
pm2 restart dragon-city-marketplace
pm2 logs dragon-city-marketplace
```

### Si hay errores de base de datos:
```bash
sudo systemctl restart postgresql
cd app && npx prisma db push
```

### Si Nginx muestra errores:
```bash
sudo nginx -t
sudo systemctl restart nginx
```

### Si hay problemas de SSL:
```bash
sudo certbot renew --dry-run
sudo systemctl reload nginx
```

## Contacto y Soporte

- Logs de aplicación: `/var/log/dragon-city-marketplace/`
- Configuración de Nginx: `/etc/nginx/sites-available/dragon-city-marketplace`
- Configuración de PM2: `ecosystem.config.js`
- Variables de entorno: `app/.env`

---

**¡Felicidades! Tu Dragon City Marketplace está funcionando correctamente.** 🎉

Guarda este checklist para futuras verificaciones y mantenimiento.
