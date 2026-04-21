# ~/nixos-config/nixos/modules/dev-agent/default.nix
{ pkgs, lib, ... }:
let
  jail = import ../pentest/jail-utils.nix { inherit pkgs lib; };
  kbPath = "/home/zagreus/nixos-config/kb";
  workspacePath = "/home/zagreus/dev-agent-workspace";

  # Worker de ejecución puro. Aider y Ollama viven en host.
  agentPkgs = with pkgs; [
    uv git curl jq
    (python312.withPackages (ps: with ps; [
      chromadb
      sentence-transformers
      pytest
      ruff
      pypdf
      requests
    ]))
  ];
in {
  # Asegura estructura input/output dentro del workspace
  systemd.tmpfiles.rules = [
    "d ${workspacePath}/input  0755 zagreus users -"
    "d ${workspacePath}/output 0755 zagreus users -"
  ];

  environment.systemPackages = [
    (jail.mkJail {
      name = "dev-agent";
      packages = agentPkgs;
      workspace = workspacePath;
      # Aislamiento total de red. Zero trust.
      allowNet = false;
      allowGPU = false;
      extraBinds = [
        { from = kbPath; to = "/kb"; }
        { from = "/home/zagreus/.gitconfig"; to = "/home/jailer/.gitconfig"; }
      ];
    })
  ];
}
