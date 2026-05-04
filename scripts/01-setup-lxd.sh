#!/usr/bin/env bash
# Instala y configura LXD con valores por defecto para el lab
set -euo pipefail

if ! command -v lxd &>/dev/null; then
  echo "Instalando LXD via snap..."
  sudo snap install lxd
fi

echo "=== Inicializando LXD ==="
echo "Acepta los valores por defecto (Enter en todo)."
echo "Lo único importante: responde 'yes' a 'Would you like to create a new local network bridge'"
echo ""
sudo lxd init

echo ""
echo "Añadiendo usuario actual al grupo lxd..."
sudo usermod -aG lxd "$USER"

echo ""
echo "✓ LXD listo"
echo ""
echo "IMPORTANTE: cierra sesión y vuelve a entrar para que el grupo lxd tenga efecto,"
echo "o ejecuta: newgrp lxd"
echo ""
echo "Verificar con: lxc launch ubuntu:22.04 test-vm --vm && lxc list"
