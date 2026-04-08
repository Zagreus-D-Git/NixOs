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
            python311
            uv
            git
            nvtopPackages.full

            # ML stack - todas consistentes en Python 3.11
            python311Packages.torch-bin
            python311Packages.torchvision-bin
            python311Packages.transformers
            python311Packages.accelerate
            python311Packages.datasets
            python311Packages.sentencepiece
            python311Packages.jupyterlab  # Añadido para notebooks

            # CUDA toolchain
            cudaPackages.cudatoolkit
            cudaPackages.cudnn
          ];

          shellHook = ''
            echo ""
            echo "🚀 LAB: Entorno de ML cargado"
            echo "🐍 Python: $(python3 --version)"
            echo "🔥 PyTorch: $(python3 -c 'import torch; print(f\"{torch.__version__} CUDA: {torch.cuda.is_available()}\")' 2>/dev/null || echo 'No detectado')"
            echo "💡 Tip: Usa 'uv pip install <paquete>' para instalar adicionales"
            echo ""
          '';
        };

        # Shell ligero para agentes
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
            echo "🤖 AGENT: Entorno ligero listo"
            echo "🔨 Instalar aider: uv tool install aider-chat"
            echo "🔗 Ollama: http://localhost:11434"
            echo "💡 Comando: aider --model ollama/llama3.2:3b"
            echo ""
          '';
        };
      };
    };
}
