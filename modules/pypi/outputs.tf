output "hosted_repositories" {
  description = "Map of environment to hosted repository name."
  value       = { for env, repo in nexus_repository_pypi_hosted.env : env => repo.name }
}

output "proxy_repository" {
  description = "Name of the proxy repository."
  value       = nexus_repository_pypi_proxy.this.name
}

output "group_repositories" {
  description = "Map of environment to group repository name."
  value       = local.group_names
}

output "publish_roles" {
  description = "Map of environment to publish role id (empty if create_roles = false)."
  value       = try(module.roles[0].publish_role_ids, {})
}

output "read_roles" {
  description = "Map of environment to read role id (empty if create_roles = false)."
  value       = try(module.roles[0].read_role_ids, {})
}

output "repository_info" {
  description = "Consolidated repository info for wiring into modules/env-roles."
  value = {
    privilege_format    = "pypi"
    hosted_repositories = { for env, repo in nexus_repository_pypi_hosted.env : env => repo.name }
    group_repositories  = local.group_names
  }
}
