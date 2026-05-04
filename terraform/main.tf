terraform {
  required_version = ">= 1.5"
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "~> 2.0"
    }
  }
}

provider "lxd" {
  remote {
    name    = "local"
    address = "unix://${var.lxd_socket}"
    default = true
  }
}

resource "lxd_instance" "ubuntu" {
  name             = var.vm_name
  image            = "ubuntu:22.04"
  type             = var.vm_type
  wait_for_network = true

  limits = {
    cpu    = var.vm_cpus
    memory = "${var.vm_memory_mb}MB"
  }

  config = {
    "user.user-data" = templatefile("${path.module}/cloud-init.yaml.tpl", {
      ssh_public_key = var.ssh_public_key
    })
  }
}
