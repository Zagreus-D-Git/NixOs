{ config, pkgs, lib, inputs, ... }:

let
  cfg = config.services.openclaw;
  openclawPkg = inputs.nix-openclaw.packages.${pkgs.system}.openclaw-gateway;
  kbPath = "/home/zagreus/nixos-config/kb";
in {
  options.services.openclaw = {
    enable = lib.mkEnableOption "OpenClaw";
    baseUrl = lib.mkOption { type = lib.types.str; default = "http://localhost:11434"; };
    model = lib.mkOption { type = lib.types.str; default = "llama3.1:8b"; };
    modelProvider = lib.mkOption { type = lib.types.str; default = "ollama"; };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.openclaw = {
      description = "OpenClaw Gateway";
      after = [ "network-online.target" "ollama.service" ];
      wants = [ "ollama.service" ];
      wantedBy = [ "multi-user.target" ];

      preStart = ''
        test -d "${kbPath}" || { echo "KB missing"; exit 1; }
        for i in $(seq 1 5); do
          ${pkgs.curl}/bin/curl -sf ${cfg.baseUrl}/api/tags && break
          sleep 2
        done
      '';

      environment = {
        OPENCLAW_MODEL_PROVIDER = cfg.modelProvider;
        OPENCLAW_BASE_URL = cfg.baseUrl;
        OPENCLAW_MODEL = cfg.model;
      };

      serviceConfig = {
        User = "zagreus";
        StateDirectory = "openclaw";
        BindReadOnlyPaths = "${kbPath}:/var/lib/openclaw/kb";
        Restart = "on-failure";
        RestartSec = "10s";
      };

      script = ''
        exec ${openclawPkg}/bin/openclaw-gateway \
          --state-dir /var/lib/openclaw \
          --kb /var/lib/openclaw/kb/memory.db \
          --listen 127.0.0.1:18765
      '';
    };
  };
}
