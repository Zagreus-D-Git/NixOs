{
  description = "NixOS LLM Agentic Lab - ASUS Vivobook M6501R";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          cudaSupport = true;
        };
      };
    in
    {
      nixosConfigurations.vivobook-lab = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
          {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.config.cudaSupport = true;
          }
        ];
      };

      devShells.${system} = {
        
        # Shell ML completo (torch, CUDA, etc.)
        default = pkgs.mkShell {
          name = "llm-lab";
          packages = with pkgs; [
            python3
            uv
            git
            nvtopPackages.full

            # ML stack - todas consistentes en Python con alias
            python3Packages.torch-bin
            python3Packages.torchvision-bin
            python3Packages.transformers
            python3Packages.accelerate
            python3Packages.datasets
            python3Packages.sentencepiece
            python3Packages.jupyterlab  # Añadido para notebooks

            # CUDA toolchain binarios nvidia, solo descarga
            cudaPackages.cudatoolkit
            cudaPackages.cudnn
          ];

          shellHook = ''
            export CUDA_PATH=${pkgs.cudaPackages.cudatoolkit}
            # Ayuda a PyTorch a encontrar las libs de NVIDIA en NixOS
            export LD_LIBRARY_PATH=${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.ncurses}/lib:$LD_LIBRARY_PATH

            echo ""
            echo "🚀 LAB: Entorno de ML cargado (Python 3.12 + CUDA)"
            echo "🐍 Python: $(python3 --version)"
            echo "🔥 PyTorch: $(python3 -c 'import torch; print(f\"{torch.__version__} CUDA: {torch.cuda.is_available()}\")' 2>/dev/null || echo 'No detectado')"
            echo "💡 Tip: Usa 'uv pip install <paquete>' para extras"
            echo ""
          '';
        };

        # ── Shell ligero para agentes ──────────────────────────────────
        agent = pkgs.mkShell {
          name = "agent-shell";
          packages = with pkgs; [
            python3
            uv
            git
            jq
            curl
            nvtopPackages.full
          ];

          shellHook = ''
            echo ""
            echo "🤖 AGENT: Entorno ligero listo"
            echo "🔨 Instalar aider: uv tool install aider-chat"
            echo "🔗 Ollama: http://localhost:11434"
            echo ""
          '';
        };
      };
    };
}
