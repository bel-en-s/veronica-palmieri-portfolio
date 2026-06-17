#!/usr/bin/env bash
# deploy.sh — Build arm64 + push al Pi + restart del contenedor.
#
# Uso:
#   ./deploy.sh                 # build + scp + restart
#   ./deploy.sh --no-build      # solo subir binario existente y restart
#   ./deploy.sh --backup        # backup de pb_data ANTES de deploy
#   ./deploy.sh --logs          # sigue los logs después de deployar
#
# Variables de entorno:
#   PI_HOST   ssh target,  default "danielaregert@danielapi.local"
#   PI_PATH   ruta en Pi,  default "~/services/vero-palmieri-portfolio"
#   CONTAINER nombre docker, default "vero-palmieri-portfolio"

set -euo pipefail

PI_HOST="${PI_HOST:-danielaregert@danielapi.local}"
PI_PATH="${PI_PATH:-~/services/vero-palmieri-portfolio}"
CONTAINER="${CONTAINER:-vero-palmieri-portfolio}"

DO_BUILD=1
DO_BACKUP=0
DO_LOGS=0

# ---- helpers ----
say()  { echo "==> $*"; }
ok()   { echo "    ✓ $*"; }
warn() { echo "    ⚠ $*"; }
die()  { echo "✗ $*" >&2; exit 1; }

# ---- args ----
for arg in "$@"; do
  case "$arg" in
    --no-build) DO_BUILD=0 ;;
    --backup)   DO_BACKUP=1 ;;
    --logs)     DO_LOGS=1 ;;
    --help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *) die "argumento desconocido: $arg" ;;
  esac
done

# ---- backup ----
if [[ "$DO_BACKUP" -eq 1 ]]; then
  STAMP=$(date +%Y%m%d-%H%M%S)
  say "Backup de pb_data → ~/backups/vero-palmieri-portfolio/"
  ssh "$PI_HOST" "
    mkdir -p ~/backups/vero-palmieri-portfolio
    tar -czf ~/backups/vero-palmieri-portfolio/pb_data-${STAMP}.tar.gz -C $PI_PATH pb_data
  "
  ok "backup pb_data-${STAMP}.tar.gz"
fi

# ---- build ----
if [[ "$DO_BUILD" -eq 1 ]]; then
  say "Generando templates templ..."
  ~/go/bin/templ generate
  ok "templ generate"

  say "Compilando para Raspberry Pi (linux/arm64)..."
  mkdir -p dist
  GOOS=linux GOARCH=arm64 go build -o dist/vero-palmieri-portfolio .
  ok "binario: $(du -h dist/vero-palmieri-portfolio | cut -f1)"
else
  warn "saltando build (--no-build); usando dist/vero-palmieri-portfolio existente"
  [[ -f dist/vero-palmieri-portfolio ]] || die "no existe dist/vero-palmieri-portfolio"
fi

# ---- upload ----
say "Subiendo archivos a $PI_HOST:$PI_PATH"
ssh "$PI_HOST" "mkdir -p $PI_PATH/dist"
scp -q dist/vero-palmieri-portfolio "$PI_HOST:$PI_PATH/dist/"
scp -q Dockerfile docker-compose.yml "$PI_HOST:$PI_PATH/"
ok "archivos sincronizados ($(du -h dist/vero-palmieri-portfolio | cut -f1))"

# ---- restart ----
say "Rebuild + restart del contenedor"
ssh "$PI_HOST" "cd $PI_PATH && docker compose up -d --build 2>&1" \
  | grep -vE "^#|^DONE|^naming|^exporting|^WARN.*FromAsCasing" || true
ok "contenedor $CONTAINER running"

# ---- smoke test ----
say "Smoke test"
sleep 2
HTTP=$(ssh "$PI_HOST" "curl -s -o /dev/null -w '%{http_code}' -H 'Host: vero.danielaregert.com.ar' http://localhost/" 2>/dev/null || echo "ERR")
if [[ "$HTTP" == "200" ]]; then
  ok "200 OK — https://vero.danielaregert.com.ar"
else
  warn "smoke test HTTP $HTTP — revisá: ssh $PI_HOST 'docker logs $CONTAINER'"
fi

# ---- logs opcionales ----
if [[ "$DO_LOGS" -eq 1 ]]; then
  say "Siguiendo logs (Ctrl+C para salir)"
  ssh "$PI_HOST" "docker logs -f --tail 30 $CONTAINER"
fi
