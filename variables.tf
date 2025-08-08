variable "ssh_password" {
  description = "SSH password for remote connection"
  type        = string
  sensitive   = true
}

variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  sensitive   = true
}
