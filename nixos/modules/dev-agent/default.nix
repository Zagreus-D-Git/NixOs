# nixos/modules/dev-agent/default.nix
{ pkgs, lib, ... }:
let
  jail = import ../pentest/jail-utils.nix { inherit pkgs lib; };
  kbPath = "/home/zagreus/nixos-config/kb";

  agentPkgs = with pkgs; [
    uv aider-chat ollama curl jq git
    (python312.withPackages (ps: with ps; [
      chromadb
      sentence-transformers
      pytest
      ruff
      pypdf
      requests  # Para llamar a OpenClaw proxy
    ]))
  ];
in {
  environment.systemPackages = [
    (jail.mkJail {
      name = "dev-agent";
      packages = agentPkgs;
      workspace = "/home/zagreus/dev-agent-workspace";
      # FIX: Aislamiento de red real. No --share-net, no internet libre
      allowNet = false;
      allowGPU = false;
      extraBinds = [
        { from = kbPath; to = "/kb"; }
        { from = "/home/zagreus/.gitconfig"; to = "/home/jailer/.gitconfig"; }
        # FIX: Workspace de salida para que el agente escriba resultados
        { from = "/home/zagreus/factory-output"; to = "/workspace/output"; }
      ];
    })
  ];

  # Proxy controlado: dev-agent solo puede hablar con Ollama vía OpenClaw
  # El jail no tiene red, pero montamos un socket Unix o usamos un wrapper
  # que el orquestador en host ejecuta en su nombre
}
