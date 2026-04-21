# ~/nixos-config/nixos/modules/kairos-proxy/default.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.kairos-proxy;
in
{
  options.services.kairos-proxy = {
    enable = lib.mkEnableOption "Kairos Proxy (filtro Ollama para jails)";
    host = lib.mkOption { type = lib.types.str; default = "127.0.0.1"; };
    port = lib.mkOption { type = lib.types.port; default = 18888; };
    ollamaUrl = lib.mkOption { type = lib.types.str; default = "http://127.0.0.1:11434"; };
    logFile = lib.mkOption { type = lib.types.str; default = "/var/log/kairos-proxy/access.log"; };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.kairos-proxy = {
      description = "Kairos LLM Proxy (deny-by-default + audit)";
      after = [ "network.target" "ollama.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.python3}/bin/python3 ${./kairos-proxy.py} --host ${cfg.host} --port ${toString cfg.port} --ollama-url ${cfg.ollamaUrl} --log-file ${cfg.logFile}";
        Restart = "always";
        DynamicUser = true;
        LogsDirectory = "kairos-proxy";
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
