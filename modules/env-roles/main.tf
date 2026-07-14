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

  # Environments for which at least one format has a separate releases repo
  # (currently only maven splits snapshots from releases).
  releaser_environments = [
    for env in var.environments : env
    if anytrue([for fmt in var.formats : contains(keys(fmt.releases_repositories), env)])
  ]
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

# Read-only "deploy" role per environment: for users and tooling that deploy
# applications and therefore only need to pull artifacts. Grants browse/read
# on each format's group repository for the environment — no write anywhere.
# Higher environments and the proxy remain reachable as pass-through via the
# group nesting.

resource "nexus_security_role" "deploy" {
  for_each = toset(var.environments)

  roleid      = "${local.role_ids[each.key]}-deploy"
  name        = "${local.role_ids[each.key]}-deploy"
  description = "Read-only access to ${each.key} group repositories (${join(", ", sort(keys(var.formats)))})"

  privileges = distinct(flatten([
    for fmt in var.formats : [
      for action in ["browse", "read"] :
      "nx-repository-view-${fmt.privilege_format}-${fmt.group_repositories[each.key]}-${action}"
    ]
  ]))
}

# Consolidated releaser role per environment: a superset of the base
# environment role. It nests the base role (inheriting hosted write and group
# read for the environment) and adds write on every format's releases
# repository (formats without a snapshots/releases split contribute nothing).
# Assigning just this role is sufficient for a releaser.

resource "nexus_security_role" "releaser" {
  for_each = toset(local.releaser_environments)

  roleid      = "${local.role_ids[each.key]}-releaser"
  name        = "${local.role_ids[each.key]}-releaser"
  description = "Superset of the ${local.role_ids[each.key]} role that adds write access to ${each.key} releases repositories (${join(", ", sort(keys(var.formats)))})"

  roles = [nexus_security_role.env[each.key].roleid]

  privileges = distinct(flatten([
    for fmt in var.formats : [
      for action in ["browse", "read", "add", "edit"] :
      "nx-repository-view-${fmt.privilege_format}-${fmt.releases_repositories[each.key]}-${action}"
    ] if contains(keys(fmt.releases_repositories), each.key)
  ]))
}
