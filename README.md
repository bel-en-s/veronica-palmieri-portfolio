# Porfolio-Artist

Template de portfolio para artistas, derivado del proyecto Porfolio-Amelia.
Single-binary en Go con [PocketBase](https://pocketbase.io) como backend (SQLite + admin),
[templ](https://templ.guide) para vistas tipadas, i18n ES/EN, lightbox de imágenes,
panel de administración propio, y endurecimiento de seguridad básico.

## Stack

- **Go** 1.26+
- **PocketBase** (embebido) — DB SQLite, auth, files, admin UI nativo en `/_/`
- **templ** — vistas tipadas server-side
- **Tailwind / Flowbite** vía CDN en templates
- Static assets embebidos en el binario (`go:embed all:static`)

## Estructura

```
.
├── cmd/build-pi.sh          # build cross-compile a linux/arm64 (Raspberry Pi)
├── deploy/                  # snippets de Caddy
├── deploy.sh                # build + scp + restart contra un host remoto
├── Dockerfile               # imagen de runtime para arm64
├── docker-compose.yml       # servicio + volumen pb_data
├── go.mod                   # module: vero-palmieri-portfolio
├── main.go                  # entrypoint PocketBase + rutas
├── migrations/              # schema PocketBase (001 base, 015 i18n, 018 SEO, 019 OG)
├── internal/
│   ├── handlers/            # rutas públicas + admin + middleware seguridad
│   ├── views/               # templ admin
│   ├── adminsession/        # sesiones admin
│   ├── ratelimit/           # rate limiting por IP
│   └── sanitize/            # sanitización HTML (bluemonday)
└── static/                  # assets embebidos (img/, css/, etc.)
```

## Primer arranque

```sh
# instalar templ si no lo tenés
go install github.com/a-h/templ/cmd/templ@latest

# generar vistas
~/go/bin/templ generate

# correr
go run . serve
```

Abrí:

- `http://localhost:8090/` — sitio público
- `http://localhost:8090/_/` — admin de PocketBase (creá superuser la primera vez)
- `http://localhost:8090/admin` — panel custom del portfolio


veroportfolio

## Cargar contenido

El proyecto arranca con schema vacío. Cargá el contenido vía:

1. **Admin custom** (`/admin`) — pensado para el flujo del artista (works, sections, hero, press, site_settings)
2. **Admin PocketBase** (`/_/`) — control total sobre colecciones y campos

Antes de poner en producción, cambiá el `site_name` ("Artist Name") en `site_settings`,
subí imágenes al hero, y cargá las obras.

## Deploy

`deploy.sh` y `deploy/Caddyfile.snippet` están parametrizados como template.
Antes de usar, ajustá:

- `PI_HOST`, `PI_PATH`, `CONTAINER` en `deploy.sh` (o pasalos por env)
- `YOUR_DOMAIN.com` en `deploy/Caddyfile.snippet`
- nombre del servicio en `docker-compose.yml` si querés algo distinto a `vero-palmieri-portfolio`

## Seguridad aplicada

- Headers (X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, CSP básica)
- CSRF vía validación Origin/Referer en POST de admin
- Validación MIME por magic bytes en uploads de imágenes
- Rate limit por IP con detección anti-spoofing en login
- Escape estricto en lightbox JS y rendering de login

## Origen

Forkeado del portfolio de Amelia Repetto y limpiado para servir como template reusable.
Datos, branding y configuración específica fueron removidos.
