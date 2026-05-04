#cloud-config
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_public_key}

apt:
  primary:
    - arches: [default]
      uri: http://es.archive.ubuntu.com/ubuntu
  security:
    - arches: [default]
      uri: http://es.archive.ubuntu.com/ubuntu

package_update: true
packages:
  - openssh-server
  - python3

runcmd:
  - systemctl enable --now ssh
