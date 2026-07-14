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
  description = "Remote URL the proxy repository points to (e.g. https://registry-1.docker.io)."
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

variable "docker_v1_enabled" {
  description = "Whether to allow clients to use the V1 API to interact with the repositories."
  type        = bool
  default     = false
}

variable "docker_force_basic_auth" {
  description = "Whether to force basic authentication (true) or allow anonymous docker pull (false)."
  type        = bool
  default     = true
}

variable "docker_http_ports" {
  description = "Optional HTTP connector port per repository. Valid keys: dev, test, prod, proxy, dev-group, test-group, prod-group. Repositories without an entry get no dedicated connector."
  type        = map(number)
  default     = {}

  validation {
    condition = alltrue([
      for k in keys(var.docker_http_ports) :
      contains(["dev", "test", "prod", "proxy", "dev-group", "test-group", "prod-group"], k)
    ])
    error_message = "docker_http_ports keys must be one of: dev, test, prod, proxy, dev-group, test-group, prod-group."
  }
}

variable "docker_proxy_index_type" {
  description = "Type of Docker Index for the proxy repository: HUB, REGISTRY, or CUSTOM."
  type        = string
  default     = "REGISTRY"

  validation {
    condition     = contains(["HUB", "REGISTRY", "CUSTOM"], var.docker_proxy_index_type)
    error_message = "docker_proxy_index_type must be one of HUB, REGISTRY, CUSTOM."
  }
}

variable "docker_proxy_index_url" {
  description = "URL of the Docker Index (required when docker_proxy_index_type is CUSTOM)."
  type        = string
  default     = null
}
