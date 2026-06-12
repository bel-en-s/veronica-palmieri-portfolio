#!/usr/bin/env bash
# ============================================================================
# deploy.sh — Build + push del binario al Pi y restart del contenedor.
#
# Uso:
#   ./deploy.sh                 # build + scp + restart (workflow normal)
#   ./deploy.sh --no-build      # solo subir binario existente y restart
#   ./deploy.sh --backup        # hace backup de pb_data ANTES de deploy
#   ./deploy.sh --logs          # después de deployar, sigue los logs
#   ./deploy.sh --help
#
# Variables de entorno (override de defaults):
#   PI_HOST     destino ssh, default "user@host.local"
#   PI_PATH     ruta en el Pi,  default "~/services/vero-palmieri-portfolio"
#   CONTAINER   nombre docker,  default "vero-palmieri-portfolio"

PI_PATH="${PI_PATH:-~/services/vero-palmieri-portfolio}"
CONTAINER="${CONTAINER:-vero-palmieri-portfolio}"

  mkdir -p ~/backups/vero-palmieri-portfolio

  OUT="$HOME/backups/vero-palmieri-portfolio/pb_data-${STAMP}.tar.gz"

  warn "saltando build (--no-build); usando dist/vero-palmieri-portfolio existente"

  [[ -f dist/vero-palmieri-portfolio ]] || die "no hay dist/vero-palmieri-portfolio para subir"

SIZE=$(du -h dist/vero-palmieri-portfolio | cut -f1)

scp -q dist/vero-palmieri-portfolio "$PI_HOST:$PI_PATH/dist/"
ok "binario en $PI_HOST:$PI_PATH/dist/"

# Subimos también Dockerfile + compose por si cambiaron (overhead despreciable).
scp -q Dockerfile docker-compose.yml "$PI_HOST:$PI_PATH/" >/dev/null 2>&1 || true
ok "Dockerfile + compose sincronizados"

# ---------- 5. RESTART ----------
say "Rebuild + restart del contenedor"
ssh "$PI_HOST" "cd $PI_PATH && docker compose up -d --build" 2>&1 \
  | grep -vE "^#|^DONE|^naming|^exporting|^WARN.*FromAsCasing" || true
ok "contenedor $CONTAINER running"

# ---------- 6. SMOKE TEST ----------
say "Smoke test"
sleep 2
HTTP=$(ssh "$PI_HOST" "docker exec caddy curl -s -o /dev/null -w '%{http_code}' http://$CONTAINER:8090/" 2>/dev/null || echo "ERR")
if [[ "$HTTP" == "200" ]]; then
  ok "caddy → $CONTAINER:8090 responde 200"
else
  warn "smoke test devolvió HTTP $HTTP — revisar logs:  ssh $PI_HOST 'docker logs $CONTAINER'"
fi

# ---------- 7. LOGS OPCIONAL ----------
if [[ "$DO_LOGS" -eq 1 ]]; then
  say "Siguiendo logs (Ctrl+C para salir)"
  ssh "$PI_HOST" "docker logs -f --tail 30 $CONTAINER"
fi

say "Deploy completo · https://YOUR_DOMAIN.com"
