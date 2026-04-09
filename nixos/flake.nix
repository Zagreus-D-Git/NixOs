{
  description = "NixOS LLM Agentic Lab - ASUS Vivobook M6501R";

  inputs = {
    # Este es un commit verificado de finales de marzo que tiene Torch 2.x y CUDA estable
    nixpkgs.url = "github:nixos/nixpkgs/ae26c043e745672f782c575a2d718b95a894a86f";
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
        modules = [ ./configuration.nix ];
      };

      devShells.${system} = {
        # ── Shell ML completo (torch, CUDA, etc.) ──────────────────────
        # Se entra con: nix develop
        default = pkgs.mkShell {
          name = "llm-lab";
          packages = with pkgs; [
            python312
            uv
            git
            nvtopPackages.full

            # ML stack binario (Cacheado para 3.12)
            python312Packages.torch-bin
            python312Packages.torchvision-bin
            python312Packages.transformers
            python312Packages.accelerate
            python312Packages.datasets
            python312Packages.sentencepiece
            python312Packages.jupyterlab

            # CUDA (Descarga de binarios NVIDIA) - no se incluyen cudapackages torch-bin usa el driver del sistema
            #cudaPackages_12.cudatoolkit
            #cudaPackages_12.cudnn
          ];

          shellHook = ''
            export CUDA_PATH=${pkgs.cudaPackages_12.cudatoolkit}
            export LD_LIBRARY_PATH=${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.ncurses}/lib:${pkgs.cudaPackages_12.cudatoolkit}/lib:$LD_LIBRARY_PATH

            echo ""
            echo "🚀 LAB: Entorno ML (Python 3.12 + CUDA 12)"
            echo "🔥 PyTorch: $(python3 -c 'import torch; print(f\"{torch.__version__} CUDA: {torch.cuda.is_available()}\")' 2>/dev/null || echo 'Error en carga')"
            echo ""
          '';
        };

        # ── Shell ligero para agentes ──────────────────────────────────
        # Se entra con: nix develop .#agent
        agent = pkgs.mkShell {
          name = "agent-shell";
          packages = with pkgs; [
            python312
            uv
            git
            jq
            curl
            nvtopPackages.full
          ];

          shellHook = ''
            echo ""
            echo "🤖 AGENT: Entorno ligero listo (Python 3.12)"
            echo "🔨 Instalar aider: uv tool install aider-chat"
            echo "🔗 Ollama: http://localhost:11434"
            echo "💡 Comando: aider --model ollama/llama3.2:3b"
            echo ""
          '';
        };
      };
    };
}
