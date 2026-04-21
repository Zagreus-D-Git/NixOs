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
    ]))
  ];
in {
  environment.systemPackages = [
    (jail.mkJail {
      name = "dev-agent";
      packages = agentPkgs;
      workspace = "/home/zagreus/dev-agent-workspace";
      allowNet = true;
      allowGPU = false;
      extraBinds = [
        { from = kbPath; to = "/kb"; }
        { from = "/home/zagreus/.gitconfig"; to = "/home/jailer/.gitconfig"; }
      ];
    })
  ];
}
