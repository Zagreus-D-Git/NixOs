# Requirements: Dev-Agent Jail Hardening

## Goal
Harden the dev-agent jail so that code-assisting workflows run only inside a minimal, explicitly bounded sandbox with no default network access and no host execution path.

## Scope
This feature applies to the jail used for Aider and related code-assistance tasks. It does not modify the host OS policy except where required to expose the jail as a declarative NixOS service or package.

## Functional Requirements

### Isolation
1. The jail MUST run in a separate bubblewrap namespace.
2. The jail MUST default to `--unshare-net`.
3. The jail MUST not have direct write access to the host home directory.
4. The jail MUST have write access only to its assigned workspace and any explicitly approved bind mounts.
5. The jail MUST mount `/kb` read-only.
6. The jail MUST not expose host-level execution privileges to the agent.

### Tooling
7. The jail MUST include only the packages needed for the coding workflow.
8. The jail MUST exclude network-facing convenience tools unless a feature spec explicitly justifies them.
9. The jail MUST include Aider only as an in-jail tool, never as a host-space execution path.
10. The jail MUST remain usable for normal code-editing workflows without requiring graphical permissions.

### Resource Control
11. The jail workspace MUST have a declarative cleanup or size policy.
12. The jail MUST not be allowed to grow logs or outputs without limit.
13. The jail MUST fail safely if required mounts or workspace paths are missing.

### Reproducibility
14. The jail MUST be defined declaratively in Nix.
15. The jail MUST use pinned flake inputs and not depend on mutable local state for its runtime definition.
16. The jail MUST work from the same configuration after rebuilds unless the spec changes.

### Safety and Exceptions
17. Any exception to isolation, package inclusion, or network access MUST be documented in the feature spec.
18. Any temporary workaround used during development MUST be explicitly marked as temporary and removed before the feature is considered complete.

## Non-Goals
- This feature does not implement the orchestrator loop.
- This feature does not migrate Chroma to cosine.
- This feature does not implement memory-graph storage.
- This feature does not redesign the host desktop or gaming specialisations.

## Acceptance Criteria
- The jail starts successfully from the declarative Nix configuration.
- The jail runs with network disabled by default.
- The jail can perform the intended coding workflow inside the workspace.
- The jail cannot write outside approved paths.
- The jail is documented in the spec set and can be validated against the requirements.
