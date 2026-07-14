variable "formats" {
  description = "Map of format key to repository info, as produced by each format module's repository_info output."
  type = map(object({
    privilege_format    = string
    hosted_repositories = map(string)
    group_repositories  = map(string)
  }))
}

variable "environments" {
  description = "Environments to create a consolidated role for. Each must be a key in every format's hosted_repositories."
  type        = list(string)
  default     = ["dev", "test", "prod"]
}

variable "role_name_prefix" {
  description = "Optional prefix for role ids and names (e.g. \"nexus\" produces nexus-dev). Null produces bare environment names (dev, test, prod)."
  type        = string
  default     = null
}
