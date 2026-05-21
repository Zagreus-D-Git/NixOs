# Tech Stack: The NixOS Factory

**OS Layer:** NixOS 26.05 (Yarara) with a unified flake architecture.

**Hardware:** Ryzen 9 laptop with NVIDIA RTX 3070, using PRIME offload.

**Inference:** Ollama with CUDA 12, fronted by Kairos Proxy for deny-by-default routing and auditability.

**Isolation:** Bubblewrap-based jails defined through `nixos/lib/jail-utils.nix` and declarative NixOS modules.

**Memory:** ChromaDB for RAG-style retrieval, with future evaluation of cosine distance instead of L2 on the lab corpus.

**Coding Workflow:** Local agent tooling such as Aider may be used only inside an explicitly jailed environment.

**Python Policy:** Prefer dependencies declared through Nix shells or `python.withPackages`; avoid mixed ad hoc environments unless temporarily necessary and documented.

**Monitoring:** Keep host-side monitoring and administrative tooling outside jailed workers.
