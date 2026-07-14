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
  description = "Cleanup policy names applied to the hosted and proxy repositories."
  type        = list(string)
  default     = []
}

variable "proxy_remote_url" {
  description = "Remote URL the proxy repository points to (e.g. https://repo1.maven.org/maven2/)."
  type        = string
}

variable "proxy_content_max_age" {
  description = "How long (minutes) to cache artifacts before rechecking the remote repository."
  type        = number
  default     = 1440
}

variable "proxy_metadata_max_age" {
  description = "How long (minutes) to cache metadata before rechecking the remote repository."
  type        = number
  default     = 1440
}

variable "negative_cache_enabled" {
  description = "Whether to cache responses for content not present in the proxied repository."
  type        = bool
  default     = true
}

variable "negative_cache_ttl" {
  description = "How long (minutes) to cache the fact that a file was not found in the proxied repository."
  type        = number
  default     = 1440
}

variable "http_client_blocked" {
  description = "Whether to block outbound connections on the proxy repository."
  type        = bool
  default     = false
}

variable "http_client_auto_block" {
  description = "Whether to auto-block outbound connections if the remote is unresponsive."
  type        = bool
  default     = false
}

variable "create_roles" {
  description = "Whether to create per-environment deploy and read roles."
  type        = bool
  default     = true
}

variable "maven_version_policy" {
  description = "What type of artifacts does this repository store: RELEASE, SNAPSHOT, or MIXED."
  type        = string
  default     = "RELEASE"

  validation {
    condition     = contains(["RELEASE", "SNAPSHOT", "MIXED"], var.maven_version_policy)
    error_message = "maven_version_policy must be one of RELEASE, SNAPSHOT, MIXED."
  }
}

variable "maven_layout_policy" {
  description = "Validate that all paths are maven artifact or metadata paths: STRICT or PERMISSIVE."
  type        = string
  default     = "STRICT"

  validation {
    condition     = contains(["STRICT", "PERMISSIVE"], var.maven_layout_policy)
    error_message = "maven_layout_policy must be one of STRICT, PERMISSIVE."
  }
}

variable "maven_content_disposition" {
  description = "Content disposition for the repositories: INLINE or ATTACHMENT."
  type        = string
  default     = "INLINE"

  validation {
    condition     = contains(["INLINE", "ATTACHMENT"], var.maven_content_disposition)
    error_message = "maven_content_disposition must be one of INLINE, ATTACHMENT."
  }
}
