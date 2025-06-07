
module.exports = {
  apps: [
    {
      name: 'dragon-city-marketplace',
      cwd: '/var/www/dragon-city-marketplace/app',
      script: 'npm',
      args: 'start',
      instances: 1,
      exec_mode: 'fork',
      
      // Variables de entorno
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      
      // Configuración de logs
      log_file: '/var/log/dragon-city-marketplace/combined.log',
      out_file: '/var/log/dragon-city-marketplace/out.log',
      error_file: '/var/log/dragon-city-marketplace/error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      
      // Configuración de reinicio automático
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      
      // Configuración de reinicio en caso de error
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000,
      
      // Configuración de cluster (opcional)
      // instances: 'max',
      // exec_mode: 'cluster',
      
      // Configuración de monitoreo
      monitoring: false,
      
      // Variables de entorno específicas para producción
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      
      // Variables de entorno para desarrollo
      env_development: {
        NODE_ENV: 'development',
        PORT: 3000
      },
      
      // Configuración de tiempo de espera
      listen_timeout: 3000,
      kill_timeout: 5000,
      
      // Configuración de merge de logs
      merge_logs: true,
      
      // Configuración de timestamp en logs
      time: true,
      
      // Configuración de source map
      source_map_support: true,
      
      // Configuración de interpretador
      interpreter: 'node',
      
      // Configuración de argumentos del interpretador
      interpreter_args: '--max-old-space-size=1024',
      
      // Configuración de cron para reinicio automático (opcional)
      // cron_restart: '0 2 * * *', // Reiniciar todos los días a las 2 AM
      
      // Configuración de ignore watch
      ignore_watch: [
        'node_modules',
        '.next',
        '.git',
        'logs'
      ],
      
      // Configuración de watch options
      watch_options: {
        followSymlinks: false,
        usePolling: false
      }
    }
  ],
  
  // Configuración de despliegue (opcional)
  deploy: {
    production: {
      user: 'ubuntu',
      host: 'localhost',
      ref: 'origin/main',
      repo: 'git@github.com:username/dragon-city-marketplace.git',
      path: '/var/www/dragon-city-marketplace',
      'pre-deploy-local': '',
      'post-deploy': 'npm install && cd app && npm install && npm run build && pm2 reload ecosystem.config.js --env production',
      'pre-setup': ''
    }
  }
};
