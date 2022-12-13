variable "ssh_key" {
  default     = "~/.ssh/id_rsa"
  description = "SSH key"
}

variable "yc_user" {
    description = "User to run instance"
    default = "ubuntu"
}

output "ip_address" {
  value       = yandex_compute_instance.vm-1.network_interface[0].nat_ip_address
  description = "Public ip adress"
}