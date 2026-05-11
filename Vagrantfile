# -*- mode: ruby -*-
# vi: set ft=ruby :

# Lab DevOps - VM Ubuntu Server via VirtualBox + Vagrant.
#
# La box ubuntu/jammy64 ya viene con SSH listo y usuario `vagrant` con sudo
# NOPASSWD, asi que no hace falta cloud-init. El provisioner solo inyecta la
# clave publica generada por scripts/01-setup-virtualbox.sh.
#
# El acceso desde el contenedor de Jenkins se hace via host.docker.internal
# (mapea al loopback del host) usando los puertos forward.

Vagrant.configure("2") do |config|
  config.vm.box      = "ubuntu/jammy64"
  config.vm.hostname = "ubuntu-devops"

  # NAT con port-forwarding: cada servicio expuesto en el host (Mac/Linux).
  # Desde Jenkins-in-Docker: host.docker.internal:<host_port>
  # Desde el host directamente: localhost:<host_port>
  config.vm.network "forwarded_port", guest: 22,   host: 2222, id: "ssh", auto_correct: false
  config.vm.network "forwarded_port", guest: 80,   host: 8081
  config.vm.network "forwarded_port", guest: 3000, host: 3000
  config.vm.network "forwarded_port", guest: 9090, host: 9090

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "ubuntu-devops"
    vb.cpus   = 2
    vb.memory = 2048
    vb.gui    = false
  end

  # Inyectar la clave publica generada en ./ssh por el script de setup.
  # La carpeta del proyecto esta sincronizada en /vagrant dentro de la VM.
  config.vm.provision "shell", inline: <<-SHELL
    set -euo pipefail
    install -d -o vagrant -g vagrant -m 700 /home/vagrant/.ssh
    if [ -f /vagrant/ssh/id_rsa.pub ]; then
      KEY=$(cat /vagrant/ssh/id_rsa.pub)
      touch /home/vagrant/.ssh/authorized_keys
      grep -qxF "$KEY" /home/vagrant/.ssh/authorized_keys || echo "$KEY" >> /home/vagrant/.ssh/authorized_keys
      chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
      chmod 600 /home/vagrant/.ssh/authorized_keys
      echo "[provision] Jenkins SSH key authorized for vagrant@$(hostname)"
    else
      echo "[provision] AVISO: /vagrant/ssh/id_rsa.pub no existe; ejecuta scripts/01-setup-virtualbox.sh antes de 'vagrant up'." >&2
    fi
    apt-get update -y
    apt-get install -y python3
  SHELL
end
