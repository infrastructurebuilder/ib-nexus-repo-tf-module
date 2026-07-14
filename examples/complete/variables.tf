variable "nexus_url" {
  description = "URL of the Nexus instance."
  type        = string
}

variable "nexus_username" {
  description = "Admin username for the Nexus instance."
  type        = string
  default     = "admin"
}

variable "nexus_password" {
  description = "Admin password for the Nexus instance."
  type        = string
  sensitive   = true
}

variable "example_users_password" {
  description = "Password for the example users. Override this; do not use the default anywhere real."
  type        = string
  sensitive   = true
  default     = "changeme-immediately"
}
