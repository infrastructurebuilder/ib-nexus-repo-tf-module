# Plans

Index of plans for this repo, newest first. Each Spec Kit feature gets one section here, with
a status line and a link to its plan in `specs/<NNN-name>/plan.md`. The rule is in the
[constitution](.specify/memory/constitution.md), under Development Workflow.

## 2026-11-20 — Adopt Spec Kit

*Status: done. Squash-merged into `develop` on 2026-11-20; `feature/specs-init` is kept.*

This phase has no spec directory, because it sets up the workflow that later features use.

- [x] Scaffold Spec Kit 1.2.3 with the Claude integration (`.specify/`, `.claude/skills/`)
- [x] Keep the rest of `.claude/` out of git in [.gitignore](.gitignore)
- [x] Draft constitution 1.0.0 from the README and the code's conventions
- [x] Create this index
- [x] Decide the release branch: git-flow release branches finished into `main`; `master` is retired
- [x] Remove the Sync Impact Report comment from the constitution and commit
- [x] Finish the branch with a squash-merge into `develop`

Follow-up outside this phase: replace `master` with `main` on the remote, and move consumers
that pin `?ref=master` to a tag.
