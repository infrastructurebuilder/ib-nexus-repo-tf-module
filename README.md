# ib-nexus-repo-tf-module

Terraform modules that create an environment-tiered repository layout in Sonatype
Nexus Repository using the [datadrivers/nexus](https://registry.terraform.io/providers/datadrivers/nexus/latest)
provider.

One module per repository format:

| Module           | Format | Privilege format |
| ---------------- | ------ | ---------------- |
| `modules/maven`  | maven2 | `maven2`         |
| `modules/pypi`   | pypi   | `pypi`           |
| `modules/npm`    | npm    | `npm`            |
| `modules/raw`    | raw    | `raw`            |
| `modules/docker` | docker | `docker`         |

The role-producing code is shared by all format modules and lives in
`modules/roles`.

## What each format module creates

For a base name `<name>` (defaults to the format, e.g. `maven`):

### Repositories

- `<name>-dev`, `<name>-test`, `<name>-prod` — hosted repositories, one per environment
- `<name>-proxy` — proxy of the upstream public repository (all formats except raw,
  which has no upstream to proxy)
- `<name>-dev-group`, `<name>-test-group`, `<name>-prod-group` — group repositories

Maven is special: because a Maven repository's version policy is exclusive,
each environment gets **two** hosted repositories instead of one —
`<name>-<env>-snapshots` (SNAPSHOT) and `<name>-<env>-releases` (RELEASE,
`ALLOW_ONCE` write policy by default so releases are immutable). Groups list
releases ahead of snapshots. The module outputs both repository names and
URLs (`snapshots_repository_urls` / `releases_repository_urls`; set
`nexus_url` to get absolute URLs).

### Group membership (order matters — first member wins on conflicts)

```text
prod-group = [ prod,  proxy      ]   # raw: [ prod ]
test-group = [ test,  prod-group ]
dev-group  = [ dev,   test-group ]

# maven: each env's hosted slot expands to [ releases, snapshots ]
dev-group  = [ dev-releases, dev-snapshots, test-group ]
```

Because groups are nested, the proxy (attached to the prod group) is always
reachable from every environment, and an artifact promoted to test or prod is
visible in dev — but never overrides the same artifact hosted in a
closer-priority repository. Resolution order seen from `dev-group` is
effectively `dev → test → prod → proxy`.

### Roles

Created via `modules/roles`; disable with `create_roles = false`.

- `<name>-<env>-publish` — browse/read/add/edit on the `<name>-<env>` hosted repo
  (for maven: the `<name>-<env>-snapshots` repo)
- `<name>-<env>-releaser` — maven only: browse/read/add/edit on the
  `<name>-<env>-releases` repo
- `<name>-<env>-read` — browse/read on the `<name>-<env>` hosted repo and the
  `<name>-<env>-group` group repo

Roles reference the repository-view privileges Nexus generates automatically
for every repository (`nx-repository-view-<format>-<repo>-<action>`).

## Consolidated environment roles (`modules/env-roles`)

Instead of assigning users one role per format, `modules/env-roles` produces a
single role per environment spanning every format you feed it:

- `dev` — write (browse/read/add/edit) on every format's `dev` hosted repo,
  read (browse/read) on every format's `dev-group`
- `test` — write on every `test` hosted repo, read on every `test-group`
- `prod` — write on every `prod` hosted repo, read on every `prod-group`
- `dev-releaser` / `test-releaser` / `prod-releaser` — a superset of the base
  environment role: it nests it (inheriting hosted/snapshot write and group
  read) and adds write on every format's releases repo for that environment
  (currently maven only). A releaser needs only this one role.
- `dev-deploy` / `test-deploy` / `prod-deploy` — read-only: browse/read on
  every format's group repo for that environment, no write anywhere. Intended
  for users and CI tooling that deploy applications and only pull artifacts.

Each role sees only its own environment's repositories. Artifacts from higher
environments and the proxy are still available as pass-through via the group
nesting (`test-group → prod-group → proxy`), because Nexus authorizes against
the repository being requested — reading through a group requires privileges
on the group only, not on its members.

Each format module exposes a `repository_info` output that wires straight in:

```hcl
module "env_roles" {
  source = "git::https://github.com/lynker/ib-nexus-repo-tf-module.git//modules/env-roles"

  formats = {
    maven  = module.maven.repository_info
    pypi   = module.pypi.repository_info
    npm    = module.npm.repository_info
    raw    = module.raw.repository_info
    docker = module.docker.repository_info
  }
}

resource "nexus_security_user" "jane" {
  userid    = "jane"
  firstname = "Jane"
  lastname  = "Dev"
  email     = "jane@example.com"
  password  = var.jane_password
  roles     = [module.env_roles.role_ids["dev"]]
}
```

Set `role_name_prefix` if bare `dev`/`test`/`prod` role ids are too generic
for your instance. If the consolidated roles are all you need, pass
`create_roles = false` to the format modules to skip the per-format roles.

## Usage

```hcl
provider "nexus" {
  url      = "https://nexus.example.com"
  username = "admin"
  password = var.nexus_password
}

module "maven" {
  source = "git::https://github.com/lynker/ib-nexus-repo-tf-module.git//modules/maven"

  proxy_remote_url = "https://repo1.maven.org/maven2/"
}

module "docker" {
  source = "git::https://github.com/lynker/ib-nexus-repo-tf-module.git//modules/docker"

  proxy_remote_url        = "https://registry-1.docker.io"
  docker_proxy_index_type = "HUB"

  docker_http_ports = {
    "dev-group" = 18079
    "dev"       = 18082
  }
}
```

See [examples/complete](examples/complete/) for all five formats together.

## Common inputs (all format modules)

| Name                                             | Description                                     | Default                                             |
| ------------------------------------------------ | ----------------------------------------------- | --------------------------------------------------- |
| `proxy_remote_url`                               | Upstream URL for the proxy repository (not raw) | (required)                                          |
| `name`                                           | Base name for all repositories                  | the format name                                     |
| `blobstore_name`                                 | Blob store for all repositories                 | `"default"`                                         |
| `write_policy`                                   | Per-environment write policy for hosted repos   | `{ dev = "ALLOW", test = "ALLOW", prod = "ALLOW" }` |
| `cleanup_policies`                               | Cleanup policy names for hosted and proxy repos | `[]`                                                |
| `online`                                         | Whether repositories accept requests            | `true`                                              |
| `strict_content_type_validation`                 | Enforce MIME type validation                    | `true`                                              |
| `proxy_content_max_age`                          | Proxy artifact cache TTL (minutes)              | `1440`                                              |
| `proxy_metadata_max_age`                         | Proxy metadata cache TTL (minutes)              | `1440`                                              |
| `negative_cache_enabled` / `negative_cache_ttl`  | Proxy not-found cache                           | `true` / `1440`                                     |
| `http_client_blocked` / `http_client_auto_block` | Proxy outbound connection controls              | `false` / `false`                                   |
| `create_roles`                                   | Create per-environment publish/read roles       | `true`                                              |

Format-specific inputs: `maven_version_policy` (proxy only),
`maven_layout_policy`, `maven_content_disposition`, `releases_write_policy`,
`nexus_url` (maven); `docker_v1_enabled`, `docker_force_basic_auth`,
`docker_http_ports`, `docker_proxy_index_type`, `docker_proxy_index_url`
(docker).

## Outputs (all format modules)

| Name                  | Description                                                                                                                                         |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `hosted_repositories` | Map of environment → hosted repository name (maven instead has `snapshots_repositories`, `releases_repositories`, and matching `*_repository_urls`) |
| `group_repositories`  | Map of environment → group repository name                                                                                                          |
| `proxy_repository`    | Proxy repository name (absent on raw)                                                                                                               |
| `publish_roles`       | Map of environment → publish (write) role id                                                                                                        |
| `releaser_roles`      | Maven only: map of environment → releaser role id                                                                                                   |
| `read_roles`          | Map of environment → read role id                                                                                                                   |
| `repository_info`     | Consolidated object for `modules/env-roles`                                                                                                         |

## Notes

- The raw module creates no proxy repository and takes no proxy-related
  inputs; its `prod-group` contains only the `prod` hosted repository.
- Docker group repositories are pull-only; pushing to a group requires a Nexus
  Pro writable group. Push to the per-environment hosted repositories instead.
- Requires Terraform >= 1.3 and datadrivers/nexus >= 2.6.
