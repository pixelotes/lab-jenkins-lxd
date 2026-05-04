variable "vm_name" {
  type    = string
  default = "ubuntu-devops"
}

variable "vm_type" {
  description = "Tipo de instancia LXD: virtual-machine o container"
  type        = string
  default     = "virtual-machine"
}

variable "vm_cpus" {
  type    = number
  default = 2
}

variable "vm_memory_mb" {
  type    = number
  default = 2048
}

variable "ssh_public_key" {
  description = "Clave pública SSH para inyectar en la VM via cloud-init. Se pasa via TF_VAR_ssh_public_key desde el pipeline."
  type        = string
  default     = ""
}

variable "lxd_socket" {
  description = "Ruta al socket Unix de LXD (snap install)"
  type        = string
  default     = "/var/snap/lxd/common/lxd/unix.socket"
}
