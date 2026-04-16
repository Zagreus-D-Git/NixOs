{ config, lib, pkgs, ... }:

let
  cfg = config.services.openclaw;
  kbPath = "${config.users.users.zagreus.home}/nixos-config/kb";

  # Stub local: proxy simple 18765 -> Ollama 11434
  openclawPkg = pkgs.writeShellScriptBin "openclaw-gateway" ''
    PORT="''${1#--port=}"
    PORT="''${PORT:-${toString cfg.port}}"
    while [[ "$1" != "" ]]; do
      case "$1" in
        --port) PORT="$2"; shift ;;
        --port=*) PORT="''${1#*=}" ;;
      esac
      shift
    done
    exec ${pkgs.socat}/bin/socat TCP-LISTEN:$PORT,reuseaddr,fork TCP:127.0.0.1:11434
  '';
in
{
  options.services.openclaw = {
    enable = lib.mkEnableOption "OpenClaw LLM Gateway";
    port = lib.mkOption {
      type = lib.types.port;
      default = 18765;
      description = "Puerto donde escucha el gateway";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.openclaw-gateway = {
      description = "OpenClaw LLM Gateway (stub local)";
      after = [ "network.target" "ollama.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${openclawPkg}/bin/openclaw-gateway --port ${toString cfg.port}";
        Restart = "always";
        DynamicUser = true;
        StateDirectory = "openclaw";
      };
      environment = {
        OPENCLAW_KB = kbPath;
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
