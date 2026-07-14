# One consolidated role per environment. Assigning a user the "dev" role
# grants write (browse/read/add/edit) on every format's dev hosted repository
# and read (browse/read) on every format's dev group repository. Access to
# other environments' artifacts and the proxy comes only as pass-through via
# the group nesting (dev-group -> test-group -> prod-group -> proxy): Nexus
# authorizes against the repository being requested, so reading through a
# group needs privileges on the group only, not on its members.
#
# Privileges referenced here are the repository-view privileges Nexus
# auto-generates for each repository:
#   nx-repository-view-<format>-<repository>-<action>

locals {
  role_ids = {
    for env in var.environments :
    env => var.role_name_prefix == null ? env : "${var.role_name_prefix}-${env}"
  }
}

resource "nexus_security_role" "env" {
  for_each = toset(var.environments)

  roleid      = local.role_ids[each.key]
  name        = local.role_ids[each.key]
  description = "Write access to ${each.key} hosted repositories and read access to ${each.key} group repositories (${join(", ", sort(keys(var.formats)))})"

  privileges = distinct(concat(
    # Write on this environment's hosted repository, per format
    flatten([
      for fmt in var.formats : [
        for action in ["browse", "read", "add", "edit"] :
        "nx-repository-view-${fmt.privilege_format}-${fmt.hosted_repositories[each.key]}-${action}"
      ]
    ]),
    # Read on this environment's group repository, per format
    flatten([
      for fmt in var.formats : [
        for action in ["browse", "read"] :
        "nx-repository-view-${fmt.privilege_format}-${fmt.group_repositories[each.key]}-${action}"
      ]
    ]),
  ))
}
