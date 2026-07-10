# Branching and Release Policy

## Branch roles

1. `develop`
- Integration branch for ongoing work.
- Source for alpha, beta, and release-candidate artifacts while pre-1.0.

2. `main`
- Release branch only.
- Must always be in releasable state.

## Merge policy

- No direct pushes to `main`.
- `main` changes only through pull requests.
- Required checks must pass before merge:
  - `Main Release Gate / build-*`
  - `Main Release Gate / golden-gate-linux`

## Release policy

- Alpha, beta, and release-candidate releases are cut from `develop` while the
  default branch remains the active pre-1.0 integration branch.
- Stable releases are cut from `main` only.
- Tags are created from the corresponding release commit.
- Release artifacts come from CI workflows.
