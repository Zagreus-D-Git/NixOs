# ~/nixos-config/nixos/modules/dev-agent/default.nix
{ pkgs, lib, ... }:
let
  jail = import ../pentest/jail-utils.nix { inherit pkgs lib; };
  kbPath = "/home/zagreus/nixos-config/kb";

  agentPkgs = with pkgs; [
    python312 uv aider-chat ollama curl jq git
    python312Packages.chromadb
    python312Packages.sentence-transformers
    python312Packages.pytest
    python312Packages.ruff
  ];
in {
  environment.systemPackages = [
    (jail.mkJail {
      name = "dev-agent";
      packages = agentPkgs;
      workspace = "/home/zagreus/dev-agent-workspace";
      allowNet = true;  # Only localhost via next step
      allowGPU = false;  # CPU-only for code tasks
      extraBinds = [
        { from = kbPath; to = "/kb"; }
        { from = "/home/zagreus/.gitconfig"; to = "/home/jailer/.gitconfig"; }
      ];
    })
  ];

  # Firewall: Agent can ONLY reach Ollama
 # networking.firewall.extraCommands = ''
 #   iptables -A OUTPUT -m owner --uid-owner $(id -u jailer) -d 127.0.0.1 -p tcp --dport 11434 -j ACCEPT
  #  iptables -A OUTPUT -m owner --uid-owner $(id -u jailer) -j REJECT
 # '';
}
