{ config, pkgs, lib,... }:

{
  imports = [./hardware-configuration.nix ./modules/pentest ./modules/openclaw ];

  # ── Nix + cachés ──────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org" # CUDA precompilado
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZBuZc3DkeT6xjo="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    auto-optimise-store = true;   # deduplica en cada build
    min-free = 5 * 1024 * 1024 * 1024;   # 5 GiB libres mínimo en disco
    max-free = 10 * 1024 * 1024 * 1024;  # intenta dejar 10 GiB libres
    keep-outputs = false;
    keep-derivations = false;  # era "keep-derivation" singular, ahora plural
  };
  nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 7d"; };


  # solo unfree, NADA de cudaSupport global
  nixpkgs.config.allowUnfree = true;

  # ── Boot ──────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest; # quieres bleeding edge
  boot.kernelParams = [ "nvidia-drm.modeset=1" "nvidia-drm.fbdev=1" ];
  boot.tmp.cleanOnBoot = true;

  # ── Red ───────────────────────────────────────────────────────
  networking.hostName = "vivobook-lab";
  networking.networkmanager.enable = true;
  networking.firewall = { enable = true; allowedTCPPorts = [ 22 ]; };

  # ── Locale ────────────────────────────────────────────────────
  time.timeZone = "America/Mexico_City";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Desktop Plasma 6 Wayland nativo ───────────────────────────
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];
  services.xserver.xkb = { layout = "us"; variant = ""; };
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true; # login ya en Wayland
  services.desktopManager.plasma6.enable = true;

  # ── GPU ───────────────────────────────────────────────────────
  hardware.graphics = { enable = true; enable32Bit = true; };
  hardware.nvidia = {
    modesetting.enable = true;
    open = true; # RTX 3070, en 2026 va bien; si CUDA falla cambia a false
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest; # matchea con kernel latest
    powerManagement.enable = true;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true; # ya te da el comando nvidia-offload
      amdgpuBusId = "PCI:231:0:0"; # confirmado con tu lspci
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  specialisation.on-the-go.configuration = {
    system.nixos.tags = [ "on-the-go" ];
    hardware.nvidia.powerManagement.finegrained = lib.mkForce true;
  };

  environment.variables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
  };

  # ── Paquetes base, SIN ML ─────────────────────────────────────
  environment.systemPackages = with pkgs; [
    vim neovim wget curl git htop btop tmux
    ripgrep fd bat eza fzf jq pciutils
    python3 uv
    nvtopPackages.full
    brave spotify ffmpeg imagemagick
    docker-compose
    heroic
    steam
    vlc
    nix-du
    ncdu
    dust
    flameshot
  ];

  # ── Servicios ─────────────────────────────────────────────────
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    host = "127.0.0.1"; # solo local
    port = 11434;
  };
  services.openclaw.enable = true; # desactivado hasta proveer paquete
  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;

  services.pipewire = { enable = true; alsa.enable = true; alsa.support32Bit = true; pulse.enable = true; };
  security.rtkit.enable = true;
  services.openssh = { enable = true; settings = { PermitRootLogin = "prohibit-password"; PasswordAuthentication = false; }; };
  services.printing.enable = true;
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;

  users.users.zagreus = {
    isNormalUser = true;
    description = "Zagreus";
    extraGroups = [ "wheel" "networkmanager" "video" "docker" "ollama" ];
    packages = with pkgs; [ kdePackages.kate kdePackages.konsole ];
  };

  services.journald.extraConfig = "Storage=persistent\nCompress=yes\nSystemMaxUse=2G";
  system.stateVersion = "25.11";
}
