output "hosted_repositories" {
  description = "Map of environment to hosted repository name."
  value       = { for env, repo in nexus_repository_docker_hosted.env : env => repo.name }
}

output "proxy_repository" {
  description = "Name of the proxy repository."
  value       = nexus_repository_docker_proxy.this.name
}

output "group_repositories" {
  description = "Map of environment to group repository name."
  value       = local.group_names
}

output "deploy_roles" {
  description = "Map of environment to deploy role id (empty if create_roles = false)."
  value       = try(module.roles[0].deploy_role_ids, {})
}

output "read_roles" {
  description = "Map of environment to read role id (empty if create_roles = false)."
  value       = try(module.roles[0].read_role_ids, {})
}

output "repository_info" {
  description = "Consolidated repository info for wiring into modules/env-roles."
  value = {
    privilege_format    = "docker"
    hosted_repositories = { for env, repo in nexus_repository_docker_hosted.env : env => repo.name }
    group_repositories  = local.group_names
  }
}
