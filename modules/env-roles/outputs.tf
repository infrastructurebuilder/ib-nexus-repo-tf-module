output "role_ids" {
  description = "Map of environment to consolidated role id."
  value       = { for env, role in nexus_security_role.env : env => role.roleid }
}

output "deploy_role_ids" {
  description = "Map of environment to read-only deploy role id."
  value       = { for env, role in nexus_security_role.deploy : env => role.roleid }
}

output "releaser_role_ids" {
  description = "Map of environment to consolidated releaser role id (only environments where a format has a releases repository)."
  value       = { for env, role in nexus_security_role.releaser : env => role.roleid }
}
