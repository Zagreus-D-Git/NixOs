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
      # ─────────────────────────────────────────────────────────────
      # CONFIGURACIÓN NIXOS
      # ─────────────────────────────────────────────────────────────
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

      # ─────────────────────────────────────────────────────────────
      # DEV SHELLS
      # ─────────────────────────────────────────────────────────────
      devShells.${system} = {

        # Shell ML completo (PyTorch, CUDA, notebooks)
        # Uso: nix develop
        default = pkgs.mkShell {
          name = "llm-lab";

          packages = with pkgs; [
            python311
            uv
            git
            nvtopPackages.full

            # ML stack - pre-compilado, no compila desde fuente
            python311Packages.torch-bin
            python311Packages.torchvision-bin
            python311Packages.transformers
            python311Packages.accelerate
            python311Packages.datasets
            python311Packages.sentencepiece
            python311Packages.jupyterlab

            # CUDA toolchain (para compilaciones si las necesitas)
            cudaPackages.cudatoolkit
            cudaPackages.cudnn
          ];

          shellHook = ''
            echo ""
            echo "🚀 LLM Lab Dev Shell"
            echo "🐍 Python: $(python3 --version)"
            echo "🔥 PyTorch: $(python3 -c 'import torch; print(f\"{torch.__version__} | CUDA: {torch.cuda.is_available()}\")' 2>/dev/null || echo 'Verificando...')"
            echo "💡 Comandos:"
            echo "   uv pip install <paquete>     # Instalar adicionales"
            echo "   jupyter lab                   # Notebooks"
            echo "   nvidia-offload python script.py  # Forzar GPU"
            echo ""
          '';
        };

        # Shell ligero para agentes (aider, herramientas CLI)
        # Uso: nix develop .#agent
        agent = pkgs.mkShell {
          name = "agent-shell";

          packages = with pkgs; [
            python311
            uv
            git
            jq
            curl
            nvtopPackages.full
          ];

          shellHook = ''
            echo ""
            echo "🤖 Agent Shell"
            echo "🔨 Instalar aider: uv tool install aider-chat"
            echo "🔗 Ollama API: http://localhost:11434"
            echo "💡 Ejemplo: aider --model ollama/llama3.2:3b --no-auto-commits"
            echo ""
          '';
        };
      };
    };
}
