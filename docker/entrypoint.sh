#!/bin/bash
set -e

# La clave SSH se genera en el host por scripts/01-setup-virtualbox.sh y
# se monta en /root/.ssh. Aqui solo verificamos su presencia para fallar
# pronto si el lab no se ha bootstrapeado.
if [ ! -f /root/.ssh/id_rsa ]; then
  echo "AVISO: /root/.ssh/id_rsa no encontrado en el contenedor de Jenkins."
  echo "Ejecuta en el host: bash scripts/01-setup-virtualbox.sh"
fi

exec /usr/bin/tini -- /usr/local/bin/jenkins.sh "$@"
