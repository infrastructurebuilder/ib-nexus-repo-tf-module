variable "name" {
  description = "Base name for all repositories created by this module. Defaults to the repository format."
  type        = string
  default     = null
}

variable "blobstore_name" {
  description = "Name of the blob store used by all repositories."
  type        = string
  default     = "default"
}

variable "online" {
  description = "Whether the repositories accept incoming requests."
  type        = bool
  default     = true
}

variable "strict_content_type_validation" {
  description = "Validate that all content uploaded is of a MIME type appropriate for the repository format."
  type        = bool
  default     = true
}

variable "write_policy" {
  description = "Write policy per environment for the hosted repositories. Keys: dev, test, prod. Values: ALLOW, ALLOW_ONCE, DENY."
  type        = map(string)
  default = {
    dev  = "ALLOW"
    test = "ALLOW"
    prod = "ALLOW"
  }

  validation {
    condition = alltrue([
      for k, v in var.write_policy :
      contains(["dev", "test", "prod"], k) && contains(["ALLOW", "ALLOW_ONCE", "DENY"], v)
    ])
    error_message = "write_policy keys must be dev/test/prod and values one of ALLOW, ALLOW_ONCE, DENY."
  }
}

variable "cleanup_policies" {
  description = "Cleanup policy names applied to the hosted repositories."
  type        = list(string)
  default     = []
}

variable "create_roles" {
  description = "Whether to create per-environment publish and read roles."
  type        = bool
  default     = true
}
