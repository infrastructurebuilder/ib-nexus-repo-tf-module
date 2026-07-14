# Nexus auto-generates repository-view privileges for every repository:
#   nx-repository-view-<format>-<repository>-<browse|read|edit|add|delete|*>
# These roles reference those generated privileges, so the repositories must
# exist before the roles are created (guaranteed here because the repository
# names are passed in from resource attributes).

resource "nexus_security_role" "deploy" {
  for_each = var.environments

  roleid      = "${var.role_prefix}-${each.key}-deploy"
  name        = "${var.role_prefix}-${each.key}-deploy"
  description = "Deploy (publish) access to the ${each.value.hosted_repository} repository"

  privileges = [
    "nx-repository-view-${var.privilege_format}-${each.value.hosted_repository}-browse",
    "nx-repository-view-${var.privilege_format}-${each.value.hosted_repository}-read",
    "nx-repository-view-${var.privilege_format}-${each.value.hosted_repository}-add",
    "nx-repository-view-${var.privilege_format}-${each.value.hosted_repository}-edit",
  ]
}

resource "nexus_security_role" "read" {
  for_each = var.environments

  roleid      = "${var.role_prefix}-${each.key}-read"
  name        = "${var.role_prefix}-${each.key}-read"
  description = "Read access to the ${each.value.hosted_repository} and ${each.value.group_repository} repositories"

  privileges = [
    "nx-repository-view-${var.privilege_format}-${each.value.hosted_repository}-browse",
    "nx-repository-view-${var.privilege_format}-${each.value.hosted_repository}-read",
    "nx-repository-view-${var.privilege_format}-${each.value.group_repository}-browse",
    "nx-repository-view-${var.privilege_format}-${each.value.group_repository}-read",
  ]
}
