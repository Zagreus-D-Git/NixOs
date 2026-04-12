Markdown
Copy
Code
Preview
# NixOS LLM Agentic Lab

A reproducible, declarative AI/ML development environment for the ASUS Vivobook M6501R, built with NixOS Flakes. This configuration provides a stable base system with GPU-accelerated local LLM inference, containerized development workflows, and modular architecture for extensibility.

---

## Table of Contents

- [Overview](#overview)
- [Hardware](#hardware)
- [Architecture](#architecture)
- [File Structure](#file-structure)
- [Quick Start](#quick-start)
- [Usage Guide](#usage-guide)
- [Specializations](#specializations)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)

---

## Overview

This project transforms an ASUS Vivobook M6501R into a portable AI laboratory. It features:

- **Hybrid GPU setup**: AMD Radeon 680M (display) + NVIDIA RTX 3070 Mobile (compute/CUDA)
- **Local LLM inference**: Ollama with CUDA acceleration
- **Reproducible ML environments**: Dev shells with PyTorch, Transformers, and CUDA toolkit
- **Declarative system**: Entire OS configuration as code
- **Battery/Performance profiles**: On-the-go specialization for mobile use

The architecture strictly separates system infrastructure (base configuration) from development tools (Flake dev shells), ensuring fast rebuilds and clean separation of concerns.

---

## Hardware

| Component | Specification | Role |
|-----------|--------------|------|
| CPU | AMD Ryzen 9 6900HX | General compute |
| iGPU | AMD Radeon 680M | Display output, power saving |
| dGPU | NVIDIA GeForce RTX 3070 Mobile 8GB | CUDA compute, LLM inference |
| RAM | 32GB DDR5 | Model loading, training |
| Storage | 1TB NVMe SSD | System, models, datasets |
| Display | 16" 1920x1080 144Hz | Primary output |
| External | HDMI 2.1 | Secondary monitor/TV |

**Bus IDs** (from `lspci`):
- NVIDIA: `01:00.0` → `PCI:1:0:0`
- AMD: `e7:00.0` → `PCI:231:0:0` (hex e7 = 231 decimal)

---

## Architecture
┌─────────────────────────────────────────┐
│           NIXOS SYSTEM LAYER            │
│  (configuration.nix - infrastructure)   │
├─────────────────────────────────────────┤
│  • Boot & kernel modules (NVIDIA/AMD)   │
│  • GPU drivers & PRIME sync             │
│  • Ollama service (CUDA-enabled)      │
│  • Docker with NVIDIA container toolkit │
│  • SSH, Bluetooth, Printing             │
│  • Base tools (git, vim, nvtop)         │
└─────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────┐
│         FLAKE DEV SHELLS LAYER          │
│    (flake.nix - development tools)      │
├─────────────────────────────────────────┤
│  default:                               │
│    • Python 3.11 + PyTorch (binaries)   │
│    • Transformers, Accelerate, Datasets │
│    • Jupyter Lab, CUDA toolkit          │
│                                         │
│  agent:                                 │
│    • Lightweight Python + uv            │
│    • For aider-chat, CLI tools          │
└─────────────────────────────────────────┘
plain
Copy

**Principle**: System layer provides infrastructure. Dev shells provide application tools. No Python ML packages in system configuration.

---

## File Structure
/etc/nixos/
├── flake.nix              # Entry point, dev shells, system config
├── flake.lock             # Pinned dependencies (auto-generated)
├── configuration.nix      # Base system configuration
├── hardware-configuration.nix  # Auto-detected hardware (imported)
└── README.md              # This file
~/projects/
└── llm-workspace/         # Your projects (outside /etc/nixos)
├── flake.nix          # Project-specific flakes (optional)
└── ...
plain
Copy

---

## Quick Start

### 1. Initial Setup

```bash
# Clone or copy configuration to /etc/nixos
sudo cp configuration.nix flake.nix /etc/nixos/
cd /etc/nixos

# First build (takes 10-30 minutes, downloads drivers)
sudo nixos-rebuild switch --flake .#vivobook-lab

# Reboot to load NVIDIA kernel modules
sudo reboot
2. Verify Installation
bash
Copy
# Check GPUs are detected
nvidia-offload nvidia-smi

# Should show RTX 3070 with driver 595.x, CUDA 12.x

# Check Ollama service
sudo systemctl status ollama
ollama list

# Check display providers (X11)
xrandr --listproviders
# Should show: Provider 0: NVIDIA, Provider 1: AMD
3. Enter Development Environment
bash
Copy
# Full ML environment (PyTorch, Jupyter, CUDA)
nix develop

# Or lightweight agent shell
nix develop .#agent
Usage Guide
System Rebuilds
bash
Copy
# Standard rebuild (after config changes)
sudo nixos-rebuild switch --flake .#vivobook-lab

# With custom label (for boot menu identification)
sudo env NIXOS_LABEL="experiment-1" nixos-rebuild switch --flake .#vivobook-lab

# Garbage collection (free disk space)
sudo nix-collect-garbage -d
Development Shells
Default ML Shell
bash
Copy
nix develop

# Inside shell:
python -c "import torch; print(torch.cuda.is_available())"  # Should print: True
jupyter lab  # Start notebook server
Agent Shell (lightweight)
bash
Copy
nix develop .#agent

# Install aider (one-time)
uv tool install aider-chat

# Use with local Ollama
aider --model ollama/llama3.2:3b --no-auto-commits
GPU Workflows
bash
Copy
# Force specific GPU
nvidia-offload python train.py        # Use RTX 3070
__NV_PRIME_RENDER_OFFLOAD=1 blender   # NVIDIA for render

# Check GPU utilization
nvtop  # Shows both AMD and NVIDIA
Specializations
Specializations allow booting into different hardware configurations without changing the base system.
Current Specializations
Table
Name	Use Case	GPU Mode	Battery
default (no suffix)	Lab work, external monitors	NVIDIA sync (always active)	~2-3 hours
on-the-go	Mobile, battery priority	PRIME offload (NVIDIA sleeps)	~5-6 hours
Switching Specializations
bash
Copy
# Boot into on-the-go mode
sudo /nix/var/nix/profiles/system/specialisation/on-the-go/bin/switch-to-configuration boot
sudo reboot

# Or select from boot menu (systemd-boot)
# Hold Space during boot → select generation with "(on-the-go)" tag

# Return to default
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration boot
sudo reboot
How It Works
The on-the-go specialization forces:
powerManagement.finegrained = true (NVIDIA can power off)
prime.sync.enable = false (don't use NVIDIA for everything)
prime.offload.enable = true (NVIDIA only when requested)
Troubleshooting
Issue: HDMI not detected
Symptoms: xrandr shows only eDP (internal), no HDMI output.
Check:
bash
Copy
xrandr --listproviders  # Should show 2 providers
If 0 providers: Xorg not loading drivers correctly.
Verify services.xserver.videoDrivers = [ "nvidia" "amdgpu" ];
Check boot.kernelModules includes all NVIDIA modules
If 1 provider (AMD only): NVIDIA not initializing.
Ensure nvidia-drm.modeset=1 in kernel params
Check hardware.nvidia.modesetting.enable = true
Solution: The current configuration uses NVIDIA sync mode, which keeps the dGPU active and should detect HDMI on boot.
Issue: Ollama won't start or no GPU detected
bash
Copy
# Check service status
sudo systemctl status ollama
sudo journalctl -u ollama -f

# Verify CUDA is available
nvidia-smi

# Test with CPU-only fallback
ollama run llama3.2:3b  # Should work even if CUDA fails
Issue: PyTorch not finding CUDA in dev shell
bash
Copy
nix develop
python -c "import torch; print(torch.version.cuda)"  # Should show 12.x

# If None or CPU-only:
# 1. Ensure nixpkgs.config.cudaSupport = true in flake
# 2. Use torch-bin, not torch (source build)
Issue: Long build times / compilation
Never use python3Packages.torch (builds from source, 4+ hours).
Always use python3Packages.torch-bin (pre-built binary with CUDA).
If you see compilation:
Check you are using -bin variants
Verify cudaSupport = true in flake config
Clear cache: rm -rf ~/.cache/nix/
Issue: Switching between laptop and external monitor
With sync.enable = true, NVIDIA handles both outputs. Just plug in HDMI—it should work automatically.
If you want dynamic switching (laptop panel off when HDMI connected), use KDE Display Settings or xrandr:
bash
Copy
xrandr --output eDP-1 --off --output HDMI-1-1 --auto
Roadmap
Phase 1: Stabilization (Current)
[x] Base system with working HDMI
[x] Ollama CUDA service
[x] Dev shells with PyTorch
[x] Specialization for battery mode
Phase 2: Modularization
[ ] Split configuration.nix into modules:
modules/nixos/gpu.nix (NVIDIA/AMD PRIME)
modules/nixos/llm.nix (Ollama, Docker)
modules/nixos/desktop.nix (KDE, audio)
[ ] Home Manager integration for user dotfiles
[ ] Secrets management (agenix or sops-nix)
Phase 3: Advanced Features
[ ] Containerized dev environments (devcontainers-nix)
[ ] Remote build cache (Cachix)
[ ] Automated specialisation switching based on AC/battery
[ ] Hyprland experimental flake (optional)
Phase 4: Documentation & Community
[ ] Video walkthrough of setup
[ ] Template repository for other ASUS laptops
[ ] Integration guides for common ML frameworks
References
NixOS Manual - NVIDIA https://nixos.wiki/wiki/Nvidia
NixOS Manual - PRIME https://nixos.wiki/wiki/Nvidia#Optimus_PRIME
Ollama NixOS Module https://search.nixos.org/options?&show=services.ollama
Nix Flakes Book https://nixos-and-flakes.thiscute.world/
License
MIT - Feel free to fork and adapt for your hardware.
Maintainer: Zagreus
Hardware: ASUS Vivobook M6501R (Ryzen 9 6900HX, RTX 3070 Mobile)
NixOS Version: 25.11 (unstable)


CURRENT SYSTEM SETUP:
configuration.nix
{ config, pkgs, lib,... }:

{
  imports = [./hardware-configuration.nix ];

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
  };
  nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 14d"; };

  # solo unfree, NADA de cudaSupport global
  nixpkgs.config.allowUnfree = true;

  # ── Boot ──────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest; # quieres bleeding edge
  boot.kernelParams = [ "nvidia-drm.modeset=1" "nvidia-drm.fbdev=1" ];

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
  ];

  # ── Servicios ─────────────────────────────────────────────────
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    host = "127.0.0.1"; # solo local
    port = 11434;
  };
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


SYSTEM flake.nix
{
  description = "Vivobook system";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    nixosConfigurations.vivobook-lab = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
    };
  };
}

LLM-AGENTIC-LAB flake.nix
{
  description = "LLM Agentic Lab - RTX 3070";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      cuda = pkgs.cudaPackages;
    in {
      devShells.${system} = {
        default = pkgs.mkShell {
          name = "llm-lab";
          packages = with pkgs; [
            python312 uv git nvtopPackages.full
            cuda.cudatoolkit
            cuda.cudnn
            aider-chat ollama
            stdenv.cc.cc.lib   # <-- provee libstdc++.so.6
            zlib
          ];
          shellHook = ''
            export CUDA_PATH=${cuda.cudatoolkit}
            export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:${cuda.cudatoolkit}/lib:${cuda.cudnn}/lib:/run/opengl-driver/lib

            test -d .venv || uv venv -p 3.12 .venv
            source .venv/bin/activate

            python -c "import torch" 2>/dev/null || uv pip install --quiet torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

            echo "🚀 LAB listo"
          '';
        };

        agent = pkgs.mkShell {
          name = "agent-shell";
          packages = with pkgs; [ python312 uv aider-chat ollama ];
          shellHook = ''
            export OLLAMA_API_BASE=http://127.0.0.1:11434
            test -d .venv-agent || uv venv -p 3.12 .venv-agent
            source .venv-agent/bin/activate
            echo "🤖 agent listo"
          '';
        };
      };
    };
}



- always refer to the user as Zagreus, codename: Mellinoe (when asked for recommendations, tips, etc);
- always add your last context update date, with this tag format: "context-090426.1809" (that example works for context update for april 9 2026 at 06:09 PM)
