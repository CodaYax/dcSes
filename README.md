
# Dragon City Marketplace

Una aplicación web completa para comprar y vender cuentas, orbes y ofertas especiales de Dragon City.

## 🚀 Características

### Para Usuarios
- **Registro y autenticación** simple con email y contraseña
- **Navegación intuitiva** por diferentes secciones (Cuentas, Orbes, Ofertas, Canales)
- **Publicación fácil** de cuentas, orbes y ofertas especiales
- **Contacto directo** vía WhatsApp con vendedores
- **Dashboard personal** para gestionar publicaciones
- **Sistema de verificación** de vendedores confiables

### Para Administradores
- **Panel de administración** completo
- **Gestión de usuarios** (verificación, permisos, eliminación)
- **Moderación de contenido** (aprobación/rechazo de publicaciones)
- **Estadísticas detalladas** del marketplace
- **Gestión de canales** de WhatsApp

### Características Técnicas
- **Diseño responsive** optimizado para móviles y desktop
- **Animaciones fluidas** con Framer Motion
- **Tema Dragon City** con colores y efectos personalizados
- **Base de datos PostgreSQL** con Prisma ORM
- **Subida de imágenes** al servidor
- **Integración WhatsApp** para comunicación directa
- **Monedas latinoamericanas** soportadas

## 🛠️ Tecnologías Utilizadas

- **Frontend**: Next.js 14, React 18, TypeScript
- **Styling**: Tailwind CSS, Radix UI
- **Animaciones**: Framer Motion
- **Base de datos**: PostgreSQL con Prisma
- **Autenticación**: NextAuth.js
- **Formularios**: React Hook Form
- **Notificaciones**: Sonner/Toast

## 📦 Instalación

### Prerrequisitos
- Node.js 18+ 
- PostgreSQL
- Yarn o npm

### Pasos de instalación

1. **Clonar el repositorio**
```bash
git clone <repository-url>
cd dragon-city-marketplace
```

2. **Instalar dependencias**
```bash
cd app
yarn install
# o
npm install
```

3. **Configurar variables de entorno**
```bash
cp .env.example .env
```

Editar `.env` con tus configuraciones:
```env
DATABASE_URL="postgresql://usuario:contraseña@localhost:5432/dragon_city_db"
NEXTAUTH_SECRET="tu-secret-key-aqui"
NEXTAUTH_URL="http://localhost:3000"
```

4. **Configurar base de datos**
```bash
# Generar cliente Prisma
npx prisma generate

# Ejecutar migraciones
npx prisma db push

# (Opcional) Poblar con datos de ejemplo
npx prisma db seed
```

5. **Crear directorios necesarios**
```bash
mkdir -p public/uploads/accounts
mkdir -p public/uploads/orbs
mkdir -p public/uploads/offers
```

6. **Ejecutar en desarrollo**
```bash
yarn dev
# o
npm run dev
```

La aplicación estará disponible en `http://localhost:3000`

## 🚀 Despliegue en Producción

### Opción 1: Vercel (Recomendado)

1. **Conectar repositorio** a Vercel
2. **Configurar variables de entorno** en el dashboard de Vercel
3. **Configurar base de datos** PostgreSQL (Supabase, PlanetScale, etc.)
4. **Desplegar** automáticamente

### Opción 2: VPS/Servidor Propio

1. **Preparar servidor**
```bash
# Instalar Node.js, PostgreSQL, PM2
sudo apt update
sudo apt install nodejs npm postgresql pm2
```

2. **Clonar y configurar**
```bash
git clone <repository-url>
cd dragon-city-marketplace/app
npm install
npm run build
```

3. **Configurar PostgreSQL**
```bash
sudo -u postgres createdb dragon_city_db
sudo -u postgres createuser dragon_user
```

4. **Configurar variables de entorno**
```bash
cp .env.example .env.production
# Editar con configuraciones de producción
```

5. **Ejecutar migraciones**
```bash
npx prisma db push
```

6. **Iniciar con PM2**
```bash
pm2 start npm --name "dragon-city" -- start
pm2 save
pm2 startup
```

### Opción 3: Docker

```dockerfile
# Dockerfile incluido en el proyecto
docker build -t dragon-city-marketplace .
docker run -p 3000:3000 dragon-city-marketplace
```

## 📁 Estructura del Proyecto

```
dragon-city-marketplace/
├── app/
│   ├── app/                    # Páginas de Next.js
│   │   ├── api/               # API routes
│   │   ├── auth/              # Páginas de autenticación
│   │   ├── admin/             # Panel de administración
│   │   ├── dashboard/         # Dashboard de usuario
│   │   ├── accounts/          # Páginas de cuentas
│   │   ├── orbs/              # Páginas de orbes
│   │   ├── offers/            # Páginas de ofertas
│   │   ├── channels/          # Páginas de canales
│   │   └── create/            # Crear publicaciones
│   ├── components/            # Componentes React
│   │   ├── ui/               # Componentes de UI
│   │   └── ...               # Otros componentes
│   ├── lib/                   # Utilidades y configuraciones
│   ├── prisma/               # Esquema de base de datos
│   ├── public/               # Archivos estáticos
│   └── types/                # Tipos de TypeScript
├── README.md
├── INSTALLATION.md
└── package.json
```

## 🔧 Configuración

### Variables de Entorno

```env
# Base de datos
DATABASE_URL="postgresql://..."

# Autenticación
NEXTAUTH_SECRET="secret-key"
NEXTAUTH_URL="http://localhost:3000"

# Opcional: Configuraciones adicionales
UPLOAD_MAX_SIZE="10485760"  # 10MB
```

### Configuración de Prisma

El esquema incluye:
- **Users**: Usuarios con roles y verificación
- **AccountListings**: Publicaciones de cuentas
- **OrbListings**: Publicaciones de orbes
- **Offers**: Ofertas especiales
- **WhatsAppChannels**: Canales de WhatsApp

## 👥 Uso

### Para Usuarios Regulares

1. **Registrarse** con email y contraseña
2. **Explorar** cuentas, orbes y ofertas disponibles
3. **Contactar vendedores** directamente vía WhatsApp
4. **Publicar** tus propias cuentas/orbes/ofertas
5. **Gestionar** publicaciones desde el dashboard

### Para Administradores

1. **Acceder** al panel de administración
2. **Revisar** y aprobar/rechazar publicaciones
3. **Gestionar usuarios** (verificar, promover, eliminar)
4. **Ver estadísticas** del marketplace
5. **Administrar** canales de WhatsApp

## 🤝 Contribuir

1. Fork el proyecto
2. Crear rama para feature (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver `LICENSE` para más detalles.

## 🆘 Soporte

Si tienes problemas o preguntas:

1. Revisa la documentación
2. Busca en issues existentes
3. Crea un nuevo issue con detalles del problema
4. Incluye logs y pasos para reproducir

## 🔮 Roadmap

- [ ] Sistema de calificaciones y reseñas
- [ ] Chat integrado en la plataforma
- [ ] Notificaciones push
- [ ] API pública para desarrolladores
- [ ] App móvil nativa
- [ ] Sistema de pagos integrado
- [ ] Múltiples idiomas
- [ ] Modo oscuro

---

Desarrollado con ❤️ para la comunidad de Dragon City
