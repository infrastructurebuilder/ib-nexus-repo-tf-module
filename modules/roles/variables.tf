variable "role_prefix" {
  description = "Prefix for role ids and names, typically the repository base name (e.g. \"maven\")."
  type        = string
}

variable "privilege_format" {
  description = "Format segment used in Nexus auto-generated repository-view privileges (e.g. \"maven2\", \"pypi\", \"npm\", \"raw\", \"docker\")."
  type        = string
}

variable "environments" {
  description = "Per-environment repository names to grant access to. Keyed by environment (dev, test, prod)."
  type = map(object({
    hosted_repository = string
    group_repository  = string
  }))
}
