locals {
  name         = coalesce(var.name, "maven")
  environments = toset(["dev", "test", "prod"])

  group_names = {
    dev  = nexus_repository_maven_group.dev.name
    test = nexus_repository_maven_group.test.name
    prod = nexus_repository_maven_group.prod.name
  }

  url_base = var.nexus_url == null ? "" : trimsuffix(var.nexus_url, "/")

  snapshots_urls = {
    for env, repo in nexus_repository_maven_hosted.snapshots :
    env => "${local.url_base}/repository/${repo.name}"
  }

  releases_urls = {
    for env, repo in nexus_repository_maven_hosted.releases :
    env => "${local.url_base}/repository/${repo.name}"
  }
}

# ── Hosted repositories: snapshots + releases per environment ────────────────
# Maven splits each environment into two hosted repos because a repository's
# version policy is exclusive: SNAPSHOT repos reject release artifacts and
# vice versa. Write access is also split: everyone with the environment role
# deploys snapshots; only the releaser role writes releases.

resource "nexus_repository_maven_hosted" "snapshots" {
  for_each = local.environments

  name   = "${local.name}-${each.key}-snapshots"
  online = var.online

  maven {
    version_policy      = "SNAPSHOT"
    layout_policy       = var.maven_layout_policy
    content_disposition = var.maven_content_disposition
  }

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

resource "nexus_repository_maven_hosted" "releases" {
  for_each = local.environments

  name   = "${local.name}-${each.key}-releases"
  online = var.online

  maven {
    version_policy      = "RELEASE"
    layout_policy       = var.maven_layout_policy
    content_disposition = var.maven_content_disposition
  }

  storage {
    blob_store_name                = var.blobstore_name
    strict_content_type_validation = var.strict_content_type_validation
    write_policy                   = lookup(var.releases_write_policy, each.key, "ALLOW_ONCE")
  }

  dynamic "cleanup" {
    for_each = length(var.cleanup_policies) > 0 ? [1] : []
    content {
      policy_names = var.cleanup_policies
    }
  }
}

# ── Proxy repository ──────────────────────────────────────────────────────────

resource "nexus_repository_maven_proxy" "this" {
  name   = "${local.name}-proxy"
  online = var.online

  maven {
    version_policy      = var.maven_version_policy
    layout_policy       = var.maven_layout_policy
    content_disposition = var.maven_content_disposition
  }

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
# Releases sit ahead of snapshots in every group;
# prod-group = [releases, snapshots, proxy];
# test-group = [releases, snapshots, prod-group];
# dev-group  = [releases, snapshots, test-group]. The proxy is therefore
# always reachable, and an artifact in a lower environment never overrides
# the same artifact in a higher-priority (closer) repository.

resource "nexus_repository_maven_group" "prod" {
  name   = "${local.name}-prod-group"
  online = var.online

  storage {
    blob_store_name                = var.blobstore_name
    strict_content_type_validation = var.strict_content_type_validation
  }

  group {
    member_names = [
      nexus_repository_maven_hosted.releases["prod"].name,
      nexus_repository_maven_hosted.snapshots["prod"].name,
      nexus_repository_maven_proxy.this.name,
    ]
  }
}

resource "nexus_repository_maven_group" "test" {
  name   = "${local.name}-test-group"
  online = var.online

  storage {
    blob_store_name                = var.blobstore_name
    strict_content_type_validation = var.strict_content_type_validation
  }

  group {
    member_names = [
      nexus_repository_maven_hosted.releases["test"].name,
      nexus_repository_maven_hosted.snapshots["test"].name,
      nexus_repository_maven_group.prod.name,
    ]
  }
}

resource "nexus_repository_maven_group" "dev" {
  name   = "${local.name}-dev-group"
  online = var.online

  storage {
    blob_store_name                = var.blobstore_name
    strict_content_type_validation = var.strict_content_type_validation
  }

  group {
    member_names = [
      nexus_repository_maven_hosted.releases["dev"].name,
      nexus_repository_maven_hosted.snapshots["dev"].name,
      nexus_repository_maven_group.test.name,
    ]
  }
}

# ── Roles ─────────────────────────────────────────────────────────────────────

module "roles" {
  source = "../roles"
  count  = var.create_roles ? 1 : 0

  role_prefix      = local.name
  privilege_format = "maven2"

  environments = {
    for env in local.environments : env => {
      hosted_repository   = nexus_repository_maven_hosted.snapshots[env].name
      group_repository    = local.group_names[env]
      releases_repository = nexus_repository_maven_hosted.releases[env].name
    }
  }
}
