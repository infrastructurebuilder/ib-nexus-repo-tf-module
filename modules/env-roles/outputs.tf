output "role_ids" {
  description = "Map of environment to consolidated role id."
  value       = { for env, role in nexus_security_role.env : env => role.roleid }
}
