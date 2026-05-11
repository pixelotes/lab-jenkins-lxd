#!/usr/bin/env bash
# Bootstrap del lab: comprueba prerrequisitos, genera la clave SSH compartida,
# arranca la VM con Vagrant y levanta Jenkins en Docker.
#
# Idempotente: puedes volver a ejecutarlo y solo hace lo que falte.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSH_DIR="${REPO_DIR}/ssh"
KEY_FILE="${SSH_DIR}/id_rsa"

echo "=== 1/4  Comprobando prerrequisitos ==="
missing=0
for bin in VBoxManage vagrant docker; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "  [x] '$bin' no encontrado en PATH"
    missing=1
  else
    echo "  [ok] $bin -> $(command -v "$bin")"
  fi
done
if ! docker compose version >/dev/null 2>&1; then
  echo "  [x] 'docker compose' (plugin v2) no disponible"
  missing=1
else
  echo "  [ok] docker compose"
fi
if [ "$missing" -ne 0 ]; then
  cat >&2 <<EOF

Faltan dependencias. En macOS:
  brew install --cask virtualbox virtualbox-extension-pack vagrant
  brew install --cask docker

En Linux (Debian/Ubuntu):
  sudo apt install virtualbox vagrant docker.io docker-compose-plugin

EOF
  exit 1
fi

echo ""
echo "=== 2/4  Clave SSH compartida (host <-> Jenkins <-> VM) ==="
mkdir -p "$SSH_DIR"
if [ ! -f "$KEY_FILE" ]; then
  ssh-keygen -t rsa -b 4096 -f "$KEY_FILE" -N "" -C "jenkins-lab" -q
  chmod 600 "$KEY_FILE"
  chmod 644 "${KEY_FILE}.pub"
  echo "  [ok] Generada en ${KEY_FILE}"
else
  echo "  [ok] Ya existe en ${KEY_FILE}"
fi

echo ""
echo "=== 3/4  Arrancando VM con Vagrant ==="
cd "$REPO_DIR"
vagrant up

echo ""
echo "=== 4/4  Levantando Jenkins en Docker ==="
docker compose up -d --build

cat <<EOF

╔══════════════════════════════════════════════════════════════╗
║  Lab listo                                                    ║
╠══════════════════════════════════════════════════════════════╣
║  Jenkins:     http://localhost:8080                           ║
║  VM SSH:      ssh -i ssh/id_rsa -p 2222 vagrant@localhost     ║
║  Tras pipeline:                                               ║
║    Apache:    http://localhost:8081                           ║
║    Prometheus http://localhost:9090                           ║
║    Grafana:   http://localhost:3000  (admin/admin)            ║
╚══════════════════════════════════════════════════════════════╝

Abre Jenkins, lanza el job 'lab-devops-virtualbox' (esta precargado).

Para destruir todo:
  docker compose down
  vagrant destroy -f
EOF
