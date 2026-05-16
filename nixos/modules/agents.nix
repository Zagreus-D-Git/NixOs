{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.kairologic.agents;
  jail = import ../lib/jail-utils.nix { inherit pkgs lib; };
  kbPath = "/home/zagreus/nixos-config/kb";

  devPkgs = with pkgs; [
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

  dataPkgs = with pkgs; [
    python312 uv ollama curl jq
    python312Packages.chromadb
    python312Packages.sentence-transformers
    python312Packages.pypdf
    python312Packages.pytesseract
    tesseract
  ];
in
{
  options.services.kairologic.agents = {
    enable = mkEnableOption "Kairologic agents framework";

    dev = {
      enable = mkEnableOption "dev-agent jail for spec-driven development";
      workspace = mkOption {
        type = types.str;
        default = "/home/zagreus/dev-agent-workspace";
        description = "Workspace for dev-agent";
      };
    };

    data = {
      enable = mkEnableOption "data-agent jail for RAG and embeddings";
      workspace = mkOption {
        type = types.str;
        default = "/home/zagreus/data-agent-workspace";
        description = "Workspace for data-agent";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      systemd.tmpfiles.rules = [
        "d ${cfg.dev.workspace}/input 0755 zagreus users -"
        "d ${cfg.dev.workspace}/output 0755 zagreus users -"
        "d ${cfg.data.workspace} 0755 zagreus users -"
        "d ${kbPath}/embeddings/chroma 0755 zagreus users -"
      ];
    }

    (mkIf cfg.dev.enable {
      environment.systemPackages = [
        (jail.mkJail {
          name = "dev-agent";
          packages = devPkgs;
          workspace = cfg.dev.workspace;
          allowNet = false;
          allowGPU = false;
          extraBinds = [
            { from = kbPath; to = "/kb"; }
            { from = "/home/zagreus/.gitconfig"; to = "/home/jailer/.gitconfig"; }
          ];
        })
      ];
    })

    (mkIf cfg.data.enable {
      environment.systemPackages = [
        (jail.mkJail {
          name = "data-agent";
          packages = dataPkgs;
          workspace = cfg.data.workspace;
          allowNet = true;
          allowGPU = true;
          extraBinds = [ { from = kbPath; to = "/kb"; } ];
        })
      ];
    })
  ]);
}
