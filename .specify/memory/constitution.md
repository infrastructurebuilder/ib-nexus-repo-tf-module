# ib-nexus-repo-tf-module Constitution

## Core Principles

### I. One Module Per Format, One Interface

- Each repository format has its own module under `modules/<format>`.
- Every format module MUST expose the common inputs and outputs listed in the README,
  including the `repository_info` output that `modules/env-roles` consumes.
- A format may differ from the common interface only where the format itself requires it,
  as maven does with separate snapshots and releases repositories and raw does by having no
  proxy. Each such difference MUST be documented in the README.
- Logic that every format needs lives in one shared module (`modules/roles`) and MUST NOT
  be copied into the format modules.

Rationale: callers wire every format the same way and feed them all to `modules/env-roles`.
That works only while the format modules stay interchangeable.

### II. The Environment Tier Contract

- Every format provides `dev`, `test` and `prod` hosted repositories and one group
  repository per environment.
- Group membership MUST nest as `prod-group = [prod, proxy]`,
  `test-group = [test, prod-group]` and `dev-group = [dev, test-group]`, so that resolution
  from `dev-group` runs dev, test, prod, proxy.
- An artifact in a higher environment or in the proxy MUST NOT override the same artifact
  hosted in a closer repository.
- A change to group membership or to its order is a breaking change under Principle IV.

Rationale: promotion between environments is the purpose of the layout. Member order decides
which artifact a build receives, so it is part of the interface.

### III. Least-Privilege Roles

- A role grants privileges only on its own environment's repositories.
- Write access is granted on hosted repositories only. Read roles cover the hosted
  repository and its group. Deploy roles are read-only.
- Visibility of higher environments and of the proxy comes from group nesting, never from
  extra privileges on those repositories.
- Role creation MUST stay optional (`create_roles`), so a caller can rely on
  `modules/env-roles` alone.

Rationale: Nexus authorizes against the repository being requested, so a privilege on a
group is enough to read through it. Granting more would let one environment's credentials
write to another.

### IV. A Stable, Documented Interface

- Every variable and output MUST have a description. A variable with a fixed set of valid
  values MUST have a validation block.
- A change to an input, an output or a default MUST update the README in the same change.
- Releases are tagged with semantic versions. A MAJOR change is any of: renaming or removing
  an input or output; changing a resource address so that the resource is recreated;
  changing a default so that existing resources change; changing group membership.
- Modules MUST NOT configure a provider. The supported Terraform and provider versions are
  declared in `versions.tf`, identically in every module, and stated in the README.

Rationale: consumers pin this module by ref and apply it to a live Nexus. An undocumented
or unversioned change reaches them as recreated repositories.

### V. The Justfile Is the Entry Point and the Gate

- The Justfile MUST provide `init`, `build`, `test`, `full-test` and `release`, and
  `release` MUST depend on `full-test`.
- `just test` MUST check formatting and validate every module and every example. It MUST
  pass before a change is merged.
- `examples/complete` MUST use every format module and `modules/env-roles`, so that
  validating it exercises the whole interface.
- People, CI and agents run `just <target>`, not the underlying tool. A missing check is
  added as a target, not run by hand.

Rationale: the same verbs in every repo mean nobody has to rediscover how this one is
checked, and a gate at the desk catches what would otherwise surface in a consumer's plan.

## Compatibility and Layout

- The modules support Terraform 1.3 or later and `datadrivers/nexus` 2.6 or later. Raising
  either floor is a breaking change under Principle IV.
- The layout is `modules/<format>` for maven, pypi, npm, raw and docker, plus
  `modules/roles`, `modules/env-roles` and `examples/complete`.
- State files and `*.tfvars` files are never committed. Credentials reach the provider
  through variables marked sensitive.

## Development Workflow

- Features follow the Spec Kit sequence: `/speckit-specify`, `/speckit-plan`,
  `/speckit-tasks`, `/speckit-implement`. Their artifacts live in `specs/<NNN-name>/`.
- The root `PLAN.md` is the index of plans. Every feature MUST have one `##` section there,
  newest first, with a `*Status:*` line and a repo-relative link to
  `specs/<NNN-name>/plan.md`. The status line MUST be kept current as the feature progresses.
- Every plan's Constitution Check MUST list Principles I to V and record a pass or a
  justified violation for each. It MUST also confirm that the feature's `PLAN.md` entry
  exists.
- Changes are kept small enough to review, and documentation lands with the change it
  describes.
- Features are developed on a `feature/<name>` branch and squash-merged into the
  integration branch, `develop`.
- Releases follow git-flow. A release is staged on a `release/<version>` branch and
  finished into `main`, where it is tagged. `main` is the production branch.
- The `master` branch is retired and replaced by `main`. Nothing new may be based on
  `master` or pin it as a ref.

## Governance

- This constitution takes precedence over other practice in this repository. Where a plan
  conflicts with it, either the plan changes or the constitution is amended first.
- An amendment is a change to this file with a stated rationale. It takes effect when a
  maintainer merges it.
- Versions follow semantic versioning. MAJOR removes or redefines a principle. MINOR adds a
  principle or a section, or materially expands one. PATCH clarifies wording.
- Compliance is checked in every plan's Constitution Check and again at review. A violation
  that is accepted MUST be justified in the plan's Complexity Tracking table.
- Day-to-day usage guidance belongs in `README.md`.

**Version**: 1.0.0 | **Ratified**: 2026-11-20 | **Last Amended**: 2026-11-20
