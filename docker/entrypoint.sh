#!/bin/bash
set -e
if [ ! -f /root/.ssh/id_rsa ]; then
  mkdir -p /root/.ssh
  ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N "" -C "jenkins-lab" -q
  chmod 600 /root/.ssh/id_rsa
  chmod 644 /root/.ssh/id_rsa.pub
  echo "SSH key generated: /root/.ssh/id_rsa.pub"
fi
exec /usr/bin/tini -- /usr/local/bin/jenkins.sh "$@"
