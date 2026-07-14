output "deploy_role_ids" {
  description = "Map of environment to deploy role id."
  value       = { for env, role in nexus_security_role.deploy : env => role.roleid }
}

output "read_role_ids" {
  description = "Map of environment to read role id."
  value       = { for env, role in nexus_security_role.read : env => role.roleid }
}
