{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ───────────────────────────────────────────────────────────────
  # NIX & SISTEMA
  # ───────────────────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };

  # ───────────────────────────────────────────────────────────────
  # BOOT & KERNEL
  # ───────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelModules = [
    "amdgpu"
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];

  # ───────────────────────────────────────────────────────────────
  # RED & SEGURIDAD
  # ───────────────────────────────────────────────────────────────
  networking.hostName = "vivobook-lab";
  networking.networkmanager.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 11434 ];  # SSH + Ollama API
  };

  # ───────────────────────────────────────────────────────────────
  # LOCALIZACIÓN
  # ───────────────────────────────────────────────────────────────
  time.timeZone = "America/Mexico_City";
  i18n.defaultLocale = "en_US.UTF-8";

  # ───────────────────────────────────────────────────────────────
  # ESCRITORIO (X11 - estable para NVIDIA)
  # ───────────────────────────────────────────────────────────────
  services.xserver.enable = true;
  services.xserver.xkb = { layout = "us"; variant = ""; };

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # NVIDIA primario para HDMI, AMD disponible
  services.xserver.videoDrivers = [ "nvidia" "amdgpu" ];

  # ───────────────────────────────────────────────────────────────
  # GPU & NVIDIA PRIME
  # ───────────────────────────────────────────────────────────────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;  # RTX 3070 - recomendado por NVIDIA 560+
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    powerManagement = {
      enable = true;
      finegrained = false;  # Desactivado: HDMI estable, NVIDIA siempre lista
    };

    prime = {
      sync.enable = true;  # Modo Lab: NVIDIA renderiza todo
      amdgpuBusId = "PCI:231:0:0";  # e7:00.0 → 231
      nvidiaBusId = "PCI:1:0:0";    # 01:00.0 → 1
    };
  };

  # ───────────────────────────────────────────────────────────────
  # ESPECIALIZACIÓN: MODO PORTÁTIL (batería)
  # ───────────────────────────────────────────────────────────────
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

  # ───────────────────────────────────────────────────────────────
  # VARIABLES DE ENTORNO (X11)
  # ───────────────────────────────────────────────────────────────
  environment.sessionVariables = {
    QT_QPA_PLATFORM = "xcb";  # Forzar X11 para Qt
    SDL_VIDEODRIVER = "x11";
  };

  # ───────────────────────────────────────────────────────────────
  # PAQUETES DEL SISTEMA (INFRAESTRUCTURA - SIN PYTHON ML)
  # ───────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Core
    vim neovim wget curl git htop btop tmux

    # Utils
    ripgrep fd bat eza fzf jq pciutils

    # Python base (versión sistema)
    python3
    uv

    # GPU/Diagnóstico
    nvtopPackages.full

    # Media/Desktop
    brave spotify ffmpeg imagemagick

    # Containers
    docker-compose

    # Wrapper PRIME (útil en modo on-the-go)
    (writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '')

    # NOTA: ollama CLI está disponible vía services.ollama
    # NOTA: aider-chat se instala vía 'uv tool install aider-chat' en devShell
  ];

  # ───────────────────────────────────────────────────────────────
  # SERVICIOS
  # ───────────────────────────────────────────────────────────────

  # Ollama: LLM local con CUDA
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
  };

  # Docker con NVIDIA
  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;

  # Audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # Periféricos
  services.printing.enable = true;
  hardware.bluetooth.enable = true;

  # Power management (perfiles manuales)
  services.power-profiles-daemon.enable = true;

  # ───────────────────────────────────────────────────────────────
  # USUARIO
  # ───────────────────────────────────────────────────────────────
  users.users.zagreus = {
    isNormalUser = true;
    description = "Zagreus";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "docker"
      "ollama"
    ];
    packages = with pkgs; [
      kdePackages.kate
      kdePackages.konsole
    ];
  };

  # ───────────────────────────────────────────────────────────────
  # LOGS & MANTENIMIENTO
  # ───────────────────────────────────────────────────────────────
  services.journald.extraConfig = ''
    Storage=persistent
    Compress=yes
    SystemMaxUse=2G
  '';

  system.stateVersion = "25.11";
}
