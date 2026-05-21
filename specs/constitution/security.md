# Security & Isolation Policy

**Worker Hygiene**
- All agent workers must default to `--unshare-net` unless a feature spec explicitly allows network access.
- Internet access is forbidden inside isolated workers unless a spec states otherwise and the risk is accepted.

**Execution Boundaries**
- Aider and similar coding tools must never run in host space for agent work.
- Jailed workers may only receive the mounts, devices, and environment variables required for the task.
- Writable access must be limited to the workspace directory and other explicitly approved paths.

**Resource Control**
- Agent workspaces must have explicit size and cleanup policies.
- Disk growth, logs, and retries must be bounded to prevent runaway storage usage.
- Resource ceilings should be defined declaratively where possible.

**Fetch-Only Integrity**
- Heavy CUDA-related builds should prefer binary caches.
- Local compilation should be avoided unless it is strictly required and explicitly accepted.

**Reproducibility**
- Prefer pinned Nix inputs and declarative module definitions.
- Avoid hidden mutable state in agent environments.
- Any exception to the policy must be documented in the relevant feature spec.
