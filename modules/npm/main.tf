locals {
  name         = coalesce(var.name, "npm")
  environments = toset(["dev", "test", "prod"])

  group_names = {
    dev  = nexus_repository_npm_group.dev.name
    test = nexus_repository_npm_group.test.name
    prod = nexus_repository_npm_group.prod.name
  }
}

# ── Hosted repositories: one per environment ─────────────────────────────────

resource "nexus_repository_npm_hosted" "env" {
  for_each = local.environments

  name   = "${local.name}-${each.key}"
  online = var.online

  storage {
    blob_store_name                = var.blobstore_name
    strict_content_type_validation = var.strict_content_type_validation
    write_policy                   = lookup(var.write_policy, each.key, "ALLOW")
  }

  dynamic "cleanup" {
    for_each = length(var.cleanup_policies) > 0 ? [1] : []
    content {
      policy_names = var.cleanup_policies
    }
  }
}

# ── Proxy repository ──────────────────────────────────────────────────────────

resource "nexus_repository_npm_proxy" "this" {
  name   = "${local.name}-proxy"
  online = var.online

  storage {
    blob_store_name                = var.blobstore_name
    strict_content_type_validation = var.strict_content_type_validation
  }

  proxy {
    remote_url       = var.proxy_remote_url
    content_max_age  = var.proxy_content_max_age
    metadata_max_age = var.proxy_metadata_max_age
  }

  negative_cache {
    enabled = var.negative_cache_enabled
    ttl     = var.negative_cache_ttl
  }

  http_client {
    blocked    = var.http_client_blocked
    auto_block = var.http_client_auto_block
  }

  dynamic "cleanup" {
    for_each = length(var.cleanup_policies) > 0 ? [1] : []
    content {
      policy_names = var.cleanup_policies
    }
  }
}

# ── Group repositories ────────────────────────────────────────────────────────
# Member order matters: Nexus resolves members in order, first match wins.
# prod-group = [prod, proxy]; test-group = [test, prod-group];
# dev-group = [dev, test-group]. The proxy is therefore always reachable, and
# an artifact in a lower environment never overrides the same artifact in a
# higher-priority (closer) repository.

resource "nexus_repository_npm_group" "prod" {
  name   = "${local.name}-prod-group"
  online = var.online

  storage {
    blob_store_name                = var.blobstore_name
    strict_content_type_validation = var.strict_content_type_validation
  }

  group {
    member_names = [
      nexus_repository_npm_hosted.env["prod"].name,
      nexus_repository_npm_proxy.this.name,
    ]
  }
}

resource "nexus_repository_npm_group" "test" {
  name   = "${local.name}-test-group"
  online = var.online

  storage {
    blob_store_name                = var.blobstore_name
    strict_content_type_validation = var.strict_content_type_validation
  }

  group {
    member_names = [
      nexus_repository_npm_hosted.env["test"].name,
      nexus_repository_npm_group.prod.name,
    ]
  }
}

resource "nexus_repository_npm_group" "dev" {
  name   = "${local.name}-dev-group"
  online = var.online

  storage {
    blob_store_name                = var.blobstore_name
    strict_content_type_validation = var.strict_content_type_validation
  }

  group {
    member_names = [
      nexus_repository_npm_hosted.env["dev"].name,
      nexus_repository_npm_group.test.name,
    ]
  }
}

# ── Roles ─────────────────────────────────────────────────────────────────────

module "roles" {
  source = "../roles"
  count  = var.create_roles ? 1 : 0

  role_prefix      = local.name
  privilege_format = "npm"

  environments = {
    for env in local.environments : env => {
      hosted_repository = nexus_repository_npm_hosted.env[env].name
      group_repository  = local.group_names[env]
    }
  }
}
