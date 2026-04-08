{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ── Nix Settings ──────────────────────────────────────────────────
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

  # ── Bootloader & Kernel ───────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Forzamos la carga de drivers para evitar que el HDMI "duerma" al bootear
  boot.kernelModules = [ "amdgpu" "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

  boot.kernelParams = [ 
    "nvidia-drm.modeset=1" 
    "nvidia-drm.fbdev=1" 
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];

  # ── Networking ────────────────────────────────────────────────────
  networking.hostName = "vivobook-lab";
  networking.networkmanager.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 11434 ]; # SSH + Ollama API
  };

  # ── Locale & Time ─────────────────────────────────────────────────
  time.timeZone = "America/Mexico_City";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Desktop Environment (Plasma 6 / Wayland) ──────────────────────
  services.xserver.enable = true;
  services.xserver.xkb = { layout = "us"; variant = ""; };
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Prioridad NVIDIA para asegurar salida HDMI activa
  services.xserver.videoDrivers = [ "nvidia" "amdgpu" ];

  # ── Graphics & NVIDIA PRIME ───────────────────────────────────────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = true; # Open kernel modules (RTX 3070)
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    powerManagement = {
      enable = true;
      finegrained = false; # Desactivado en Lab para evitar desconexión de HDMI
    };

    prime = {
      sync.enable = true; # Modo Nuclear: NVIDIA renderiza, HDMI garantizado
      amdgpuBusId = "PCI:231:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Especialización para uso portátil (más batería, sin HDMI)
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
    NIXOS_OZONE_WL = "1";    # Fix para apps Electron en Wayland
    QT_QPA_PLATFORM = "wayland";
  };

  environment.systemPackages = with pkgs; [
    # Infra & Core
    vim neovim wget curl git htop btop tmux
    ripgrep fd bat eza fzf jq pciutils uv python3
    
    # Media & Desktop
    brave spotify ffmpeg imagemagick docker-compose
    nvtopPackages.full

    # PRIME Offload Wrapper (útil en modo on-the-go)
    (writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '')
  ];

  # ── Services (LLM, Docker, Audio) ─────────────────────────────────
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
  };

  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  services.printing.enable = true;
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;

  # ── User Account ──────────────────────────────────────────────────
  users.users.zagreus = {
    isNormalUser = true;
    description = "Zagreus";
    extraGroups = [ "wheel" "networkmanager" "video" "docker" "ollama" ];
    packages = with pkgs; [
      kdePackages.kate
      kdePackages.konsole
    ];
  };

  # ── Maintenance & Logs ───────────────────────────────────────────
  services.journald.extraConfig = "Storage=persistent\nCompress=yes\nSystemMaxUse=2G";
  
  system.stateVersion = "25.11";

  # ── Python Environment ───────────────────────────────────────────
  environment.systemPackages += with pkgs; [
    python39Packages.torch-bin
    python39Packages.transformers
    python39Packages.pytorch-lightning
  ];

  # Ensure the correct version of PyTorch is used if needed
  environment.systemPackages += with pkgs; [
    (python39Packages.torch-bin.override {
      version = "1.12.1";
      sha256 = "..."; # Replace with the actual SHA-256 hash for the specified version
    })
  ];
}
