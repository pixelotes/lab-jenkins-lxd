# Lab DevOps (LXD): Terraform + Ansible + Jenkins con Docker
### LXD · Ubuntu Server · Apache · Prometheus · Grafana

Versión automatizada del lab. LXD descarga la imagen, inyecta la clave SSH
via cloud-init y devuelve la IP directamente. Sin plantillas, sin APIs de terceros.

---

## Prerrequisitos

- **LXD** instalado e inicializado (una vez por máquina):

```bash
sudo snap install lxd && sudo lxd init
sudo usermod -aG lxd $USER  # cerrar sesión y volver a entrar
bash scripts/01-setup-lxd.sh
```

- **Docker**

---

## Arrancar

```bash
docker compose up -d
```

La clave SSH se genera automáticamente en `./ssh/` al primer arranque. El pipeline ya está precargado en Jenkins — solo hay que ejecutarlo.

El job se llama `lab-devops-lxd` y está disponible en [http://localhost:8080](http://localhost:8080) en cuanto Jenkins termine de arrancar.


---

## Cómo funciona el contenedor Terraform con LXD

Solo necesita el socket Unix de LXD montado. Sin `--privileged`, sin APIs HTTP:

```mermaid
flowchart TD
    A["Terraform\n(Docker container)"] -->|"-v unix.socket"| B["LXD Unix socket\n/var/snap/lxd/common/lxd/unix.socket"]
    B --> C["LXD daemon\n(host)"]
    A -->|"lxd_instance 'ubuntu-devops'"| D["terraform-lxd/lxd provider"]
    D -->|"image = ubuntu:22.04\nuser.user-data = cloud-init"| C
    C -->|"SSH key inyectada\nen primer boot"| E["VM ubuntu-devops\nIP + SSH listos"]
```

---

## Flujo del pipeline

```mermaid
sequenceDiagram
    actor Dev
    participant Jenkins
    participant Terraform as Terraform (Docker)
    participant LXD as LXD daemon
    participant VM as ubuntu-devops (VM)
    participant Ansible as Ansible (Docker)

    Dev->>Jenkins: Build Now
    Jenkins->>Terraform: docker run ... init
    Terraform-->>Jenkins: providers descargados

    Jenkins->>Terraform: docker run ... apply
    Terraform->>LXD: lxd_instance + cloud-init
    LXD->>VM: boot + SSH key inyectada
    VM-->>LXD: IP asignada
    LXD-->>Terraform: ipv4_address
    Terraform-->>Jenkins: vm_ip output

    Jenkins->>Jenkins: Esperar SSH (port 22)
    VM-->>Jenkins: SSH disponible

    Jenkins->>Ansible: docker run ... playbook.yml
    Ansible->>VM: apt install apache2, prometheus, grafana
    Ansible->>VM: habilitar servicios
    VM-->>Ansible: ok (19 tasks)
    Ansible-->>Jenkins: PLAY RECAP ok=19 failed=0

    Jenkins->>VM: curl Apache :80
    Jenkins->>VM: curl Prometheus :9090/-/healthy
    Jenkins->>VM: curl Grafana :3000/api/health
    VM-->>Jenkins: 200 OK × 3
    Jenkins-->>Dev: SUCCESS ✓
```

---

## Destruir

```bash
docker run --rm \
  -v /var/snap/lxd/common/lxd/unix.socket:/var/snap/lxd/common/lxd/unix.socket \
  -v $(pwd)/terraform:/terraform \
  -w /terraform \
  -e TF_VAR_ssh_public_key="$(cat ~/.ssh/id_rsa.pub)" \
  lab-lxd-terraform:latest destroy -auto-approve
```

O directamente: `lxc delete ubuntu-devops --force`

---
