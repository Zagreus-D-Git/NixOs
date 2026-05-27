{ config, lib, pkgs, ... }:

{
  services.open-webui = {
    enable = true;
    host = "127.0.0.1";
    port = 3000;
    openFirewall = false;

    environment = {
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
      WEBUI_AUTH = "True";
      ENABLE_SIGNUP = "True";
      ENABLE_OLLAMA_API = "True";
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/open-webui 0750 root root -"
  ];
}
