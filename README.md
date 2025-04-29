# Easy DDNS for Cloudflare

Actualiza automáticamente registros DNS tipo A en Cloudflare con tu IP pública actual, ideal para conexiones con IP dinámica. El proyecto se ejecuta en un contenedor Docker Alpine con `cron` para actualizaciones periódicas.

# ¿Qué necesitas?

Solo necesitas tener instalado:
- Docker
- Docker Compose

# Crea un archivo `.env` con el siguiente contenido:

```env
ZONE_ID=tu_zone_id
API_TOKEN=tu_token_de_cloudflare
DNS_NAMES=admin.tudominio.com,x.tudominio.com,otro.tudominio.com
```
