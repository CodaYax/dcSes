# 🚀 Dragon City Marketplace - Inicio Rápido

## Instalación en 4 Pasos

### 1. Preparar el Sistema
```bash
sudo ./install_deps.sh
```

### 2. Configurar Base de Datos
```bash
sudo ./setup_database.sh
```

### 3. Configurar Nginx
```bash
sudo ./nginx_config.sh
```

### 4. Desplegar Aplicación
```bash
./deploy.sh
```

## ✅ Verificación

Después del despliegue, verifica que todo funcione:

```bash
# Verificar servicios
sudo systemctl status nginx
sudo systemctl status postgresql
pm2 status

# Verificar aplicación
curl http://localhost:3000
```

## 🔧 Comandos Útiles

```bash
# Ver logs
pm2 logs dragon-city-marketplace

# Reiniciar aplicación
pm2 restart dragon-city-marketplace

# Crear backup
./backup.sh

# Actualizar aplicación
./deploy.sh
```

## 📖 Documentación Completa

Para instrucciones detalladas, consulta: `DEPLOYMENT_GUIDE.md`

## 🆘 Problemas Comunes

- **Error 502**: Verificar que la aplicación esté corriendo con `pm2 status`
- **Error de DB**: Verificar conexión con `psql -h localhost -U dragonuser -d dragondb`
- **Error SSL**: Verificar certificados con `sudo certbot certificates`

¡Tu Dragon City Marketplace estará funcionando en minutos! 🐉
