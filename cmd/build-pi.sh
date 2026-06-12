#!/bin/bash
set -euo pipefail

echo "==> Generando templates templ..."
~/go/bin/templ generate

echo "==> Compilando para Raspberry Pi (linux/arm64)..."
mkdir -p dist
GOOS=linux GOARCH=arm64 go build -o dist/vero-palmieri-portfolio .

echo "==> Listo: dist/vero-palmieri-portfolio ($(du -h dist/vero-palmieri-portfolio | cut -f1))"
