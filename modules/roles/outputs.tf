output "publish_role_ids" {
  description = "Map of environment to publish role id."
  value       = { for env, role in nexus_security_role.publish : env => role.roleid }
}

output "releaser_role_ids" {
  description = "Map of environment to releaser role id (only environments with a releases_repository)."
  value       = { for env, role in nexus_security_role.releaser : env => role.roleid }
}

output "read_role_ids" {
  description = "Map of environment to read role id."
  value       = { for env, role in nexus_security_role.read : env => role.roleid }
}
