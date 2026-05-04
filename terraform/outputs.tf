output "vm_ip" {
  value = lxd_instance.ubuntu.ipv4_address
}

output "vm_name" {
  value = lxd_instance.ubuntu.name
}
