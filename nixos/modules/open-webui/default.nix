{ config, lib, pkgs, ... }:

let
  cfg = config.services.open-webui;
in
{
  options.services.open-webui = {
    enable = lib.mkEnableOption "Open WebUI host-facing chat and KB UI";
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Host port for Open WebUI";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/open-webui";
      description = "Persistent data directory";
    };
    kbDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/zagreus/nixos-config/kb";
      description = "Read-only knowledge base directory";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;
    hardware.nvidia-container-toolkit.enable = true;

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 root root -"
    ];

    virtualisation.oci-containers.containers.open-webui = {
      image = "ghcr.io/open-webui/open-webui:cuda";
      autoStart = true;

      ports = [
        "127.0.0.1:${toString cfg.port}:8080"
      ];

      volumes = [
        "${cfg.dataDir}:/app/backend/data"
        "${cfg.kbDir}:/data/kb:ro"
      ];

      environment = {
        OLLAMA_BASE_URL = "http://127.0.0.1:11434";
        WEBUI_AUTH = "True";
        ENABLE_SIGNUP = "False";
      };

      extraOptions = [
        "--gpus=all"
      ];
    };
  };
}
