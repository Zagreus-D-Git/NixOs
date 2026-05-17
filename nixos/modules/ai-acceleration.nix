{ config, lib, pkgs, ... }:

{
  nix.settings = {
  experimental-features = [ "nix-command" "flakes" ];
    # --- Cachés Binarios (Evita compilar CUDA) ---
    substituters = [
      "https://cache.nixos-cuda.org"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"

    ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="

    ];

    # Authorize your user profile to pass substitution channels to the nix-daemon
    trusted-users = [ "root" "zagreus" ];

    # --- Optimización de Almacenamiento (Tus OBS) ---
    auto-optimise-store = true;
    min-free = 5 * 1024 * 1024 * 1024;  # 5 GiB
    max-free = 10 * 1024 * 1024 * 1024; # 10 GiB
    keep-outputs = false;
    keep-derivations = false;
  };

  #nixpkgs.config.allowUnfree = true; # already in configuration.nix

  # --- Gestión Automática de Licencias ---
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "cuda_cccl" "cuda_cudart" "cuda_nvcc" "libcublas" "libcurand"
    "libcusolver" "libcusparse" "libcufft" "nvidia-x11"
    "nvidia-settings" "nvidia-persistenced" "torch"
  ];
}
