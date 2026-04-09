{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ── Nix ───────────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 14d"; };
  nixpkgs.config = { allowUnfree = true; cudaSupport = true; };

  # ── Boot ──────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "amdgpu" "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  boot.kernelParams = [ 
    "nvidia-drm.modeset=1" 
    "nvidia-drm.fbdev=1" 
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];

  # ── Network ───────────────────────────────────────────────────
  networking.hostName = "vivobook-lab";
  networking.networkmanager.enable = true;
  networking.firewall = { enable = true; allowedTCPPorts = [ 22 11434 ]; };

  # ── Locale ────────────────────────────────────────────────────
  time.timeZone = "America/Mexico_City";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Desktop Environment (Plasma 6 / Wayland) ──────────────────────
services.xserver.enable = true;
services.xserver.xkb = { layout = "us"; variant = ""; };
services.displayManager.sddm.enable = true;
services.desktopManager.plasma6.enable = true;

  # NVIDIA primero para HDMI, AMD disponible
  services.xserver.videoDrivers = [ "modesetting" "nvidia" ];

  # ── GPU ───────────────────────────────────────────────────────
  hardware.graphics = { enable = true; enable32Bit = true; };

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;  # RTX 3070 - open recomendado por NVIDIA
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    powerManagement = {
      enable = true;
      finegrained = false;  # Desactivado para HDMI estable
    };

    prime = {
      offload.enable = true;  # Modo Lab: sync NVIDIA siempre activa - offload regula temperatura auto
      enableOffloadCmd = true; # esto da el comando 'nvidia-offload' por si acaso
      amdgpuBusId = "PCI:231:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Especialización para batería (on-the-go)
  specialisation = {
    on-the-go.configuration = {
      system.nixos.tags = [ "on-the-go" ];
      hardware.nvidia = {
        powerManagement.finegrained = lib.mkForce true;
        prime.sync.enable = lib.mkForce false;
        prime.offload = {
          enable = lib.mkForce true;
          enableOffloadCmd = lib.mkForce true;
        };
      };
    };
  };

  # ── System Environment & Variables ────────────────────────────────
environment.variables = {
  NIXOS_OZONE_WL = "1";    # Necesario para Brave/Spotify y apps Electron
  QT_QPA_PLATFORM = "wayland";
};

  # ── Packages del Sistema (SIN Python ML) ──────────────────────
  # Python base (sin ML stack)
  environment.systemPackages = with pkgs; [
    # Core
    vim neovim wget curl git htop btop tmux
    ripgrep fd bat eza fzf jq pciutils
    
    # Python base (3.11 para general uso)
    python3
    uv       # Gestor de paquetes Python
    
    # GPU/Diagnóstico
    nvtopPackages.full
    
    # Media/Desktop
    brave spotify ffmpeg imagemagick
    
    # Containers
    docker-compose

    # Wrapper PRIME
    (writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '')
  ];

  # ── Services ──────────────────────────────────────────────────
  services.ollama = { enable = true; acceleration = "cuda"; }; #nix se encarga de los binarios correctos
  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;

  services.pipewire = { enable = true; alsa.enable = true; alsa.support32Bit = true; pulse.enable = true; };
  security.rtkit.enable = true;

  services.openssh = { enable = true; settings = { PermitRootLogin = "prohibit-password"; PasswordAuthentication = false; }; };
  services.printing.enable = true;
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;

  # ── User ──────────────────────────────────────────────────────
  users.users.zagreus = {
    isNormalUser = true;
    description = "Zagreus";
    extraGroups = [ "wheel" "networkmanager" "video" "docker" "ollama" ];
    packages = with pkgs; [ kdePackages.kate kdePackages.konsole ];
  };

  # ── Logs ──────────────────────────────────────────────────────
  services.journald.extraConfig = "Storage=persistent\nCompress=yes\nSystemMaxUse=2G";
  
  system.stateVersion = "25.11";
}
