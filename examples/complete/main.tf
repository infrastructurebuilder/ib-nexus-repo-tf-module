terraform {
  required_version = ">= 1.3"

  required_providers {
    nexus = {
      source  = "datadrivers/nexus"
      version = "~> 2.6"
    }
  }
}

provider "nexus" {
  url      = var.nexus_url
  username = var.nexus_username
  password = var.nexus_password
}

module "maven" {
  source = "../../modules/maven"

  proxy_remote_url = "https://repo1.maven.org/maven2/"
}

module "pypi" {
  source = "../../modules/pypi"

  proxy_remote_url = "https://pypi.org/"
}

module "npm" {
  source = "../../modules/npm"

  proxy_remote_url = "https://registry.npmjs.org/"
}

module "raw" {
  source = "../../modules/raw"
}

module "docker" {
  source = "../../modules/docker"

  proxy_remote_url        = "https://registry-1.docker.io"
  docker_proxy_index_type = "HUB"

  # Docker clients connect on dedicated ports; expose the groups (pull)
  # and hosted repos (push) that need direct access.
  docker_http_ports = {
    "dev-group"  = 18079
    "test-group" = 18080
    "prod-group" = 18081
    "dev"        = 18082
    "test"       = 18083
    "prod"       = 18084
  }
}

# Consolidated per-environment roles: assigning "dev" grants write on every
# format's dev hosted repo and read on every format's dev group repo, with
# pass-through to higher environments and the proxy via group nesting.
module "env_roles" {
  source = "../../modules/env-roles"

  formats = {
    maven  = module.maven.repository_info
    pypi   = module.pypi.repository_info
    npm    = module.npm.repository_info
    raw    = module.raw.repository_info
    docker = module.docker.repository_info
  }
}

output "environment_roles" {
  value = module.env_roles.role_ids
}

# ── Example users: one per environment role ───────────────────────────────────
# A single role assignment gives each user write access to their environment's
# hosted repos (all formats) and read access to their environment's group
# repos, which pass through to everything above them in the chain.

resource "nexus_security_user" "dev_user" {
  userid    = "dana.dev"
  firstname = "Dana"
  lastname  = "Developer"
  email     = "dana.dev@example.com"
  password  = var.example_users_password
  status    = "active"

  roles = [module.env_roles.role_ids["dev"]]
}

resource "nexus_security_user" "test_user" {
  userid    = "terry.test"
  firstname = "Terry"
  lastname  = "Tester"
  email     = "terry.test@example.com"
  password  = var.example_users_password
  status    = "active"

  roles = [module.env_roles.role_ids["test"]]
}

resource "nexus_security_user" "prod_user" {
  userid    = "parker.prod"
  firstname = "Parker"
  lastname  = "Publisher"
  email     = "parker.prod@example.com"
  password  = var.example_users_password
  status    = "active"

  roles = [module.env_roles.role_ids["prod"]]
}

output "maven" {
  value = {
    hosted = module.maven.hosted_repositories
    groups = module.maven.group_repositories
    proxy  = module.maven.proxy_repository
    deploy = module.maven.deploy_roles
    read   = module.maven.read_roles
  }
}
