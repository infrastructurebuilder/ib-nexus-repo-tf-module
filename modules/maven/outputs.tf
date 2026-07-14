output "snapshots_repositories" {
  description = "Map of environment to snapshots hosted repository name."
  value       = { for env, repo in nexus_repository_maven_hosted.snapshots : env => repo.name }
}

output "releases_repositories" {
  description = "Map of environment to releases hosted repository name."
  value       = { for env, repo in nexus_repository_maven_hosted.releases : env => repo.name }
}

output "snapshots_repository_urls" {
  description = "Map of environment to snapshots repository URL (server-relative path unless nexus_url is set)."
  value       = local.snapshots_urls
}

output "releases_repository_urls" {
  description = "Map of environment to releases repository URL (server-relative path unless nexus_url is set)."
  value       = local.releases_urls
}

output "proxy_repository" {
  description = "Name of the proxy repository."
  value       = nexus_repository_maven_proxy.this.name
}

output "group_repositories" {
  description = "Map of environment to group repository name."
  value       = local.group_names
}

output "publish_roles" {
  description = "Map of environment to publish role id, granting write on the snapshots repository (empty if create_roles = false)."
  value       = try(module.roles[0].publish_role_ids, {})
}

output "releaser_roles" {
  description = "Map of environment to releaser role id, granting write on the releases repository (empty if create_roles = false)."
  value       = try(module.roles[0].releaser_role_ids, {})
}

output "read_roles" {
  description = "Map of environment to read role id (empty if create_roles = false)."
  value       = try(module.roles[0].read_role_ids, {})
}

output "repository_info" {
  description = "Consolidated repository info for wiring into modules/env-roles. hosted_repositories points at the snapshots repos so environment roles grant snapshot write access; releases access comes from the releaser roles."
  value = {
    privilege_format      = "maven2"
    hosted_repositories   = { for env, repo in nexus_repository_maven_hosted.snapshots : env => repo.name }
    group_repositories    = local.group_names
    releases_repositories = { for env, repo in nexus_repository_maven_hosted.releases : env => repo.name }
  }
}
