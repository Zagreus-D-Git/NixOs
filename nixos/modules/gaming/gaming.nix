# Ubicación: /home/zagreus/nixos-config/nixos/modules/gaming/gaming.nix
{ config, pkgs, lib, ... }:

{
  # Herramientas base que asisten al gaming
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  specialisation.gaming.configuration = {
    system.nixos.tags = [ "gaming-mode" ];

    # AISLAMIENTO: Apagar Ollama para recuperar VRAM de la 3070
    services.ollama.enable = lib.mkForce false;

    # OPTIMIZACIÓN GPU: Máximo rendimiento
    hardware.nvidia.powerManagement.enable = lib.mkForce false;

    # PAQUETES: Movidos aquí para limpieza del sistema base
    environment.systemPackages = with pkgs; [
      heroic
      steam
      mangohud
      protonup-qt
    ];

    # Configuración de Steam específica
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };

    # Kernel Tweaks para Gaming (Proton/Wine)
    boot.kernel.sysctl = {
      "vm.max_map_count" = 2147483642;
    };
  };
}
