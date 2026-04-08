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

      # Agrupamos todos los shells bajo el mismo sistema
      devShells.${system} = {
        
        # ── Shell por defecto (ML con PyTorch & CUDA) ──
        # Se entra con: nix develop
        default = pkgs.mkShell {
          name = "llm-lab";
          packages = with pkgs; [
            python39
            uv
            git
            nvtopPackages.full

            # ML stack
            python39Packages.torch-bin
            python39Packages.torchvision-bin
            python39Packages.transformers
            python39Packages.accelerate
            python39Packages.datasets
            python39Packages.sentencepiece

            # CUDA toolchain
            cudaPackages.cudatoolkit
            cudaPackages.cudnn
          ];

          shellHook = ''
            echo ""
            echo "🚀 LAB: Entorno de ML cargado"
            echo "🐍 Python: $(python39 --version)"
            echo "📟 CUDA: $(python39 -c 'import torch; print(torch.cuda.is_available())' 2>/dev/null || echo 'No detectado')"
            echo "💡 Tip: Si usas el modo on-the-go, usa 'nvidia-offload python <script>'"
            echo ""
          '';
        };

        # ── Shell de Agente (Ligero para Aider/Herramientas) ──
        # Se entra con: nix develop .#agent
        agent = pkgs.mkShell {
          name = "agent-shell";
          packages = with pkgs; [
            python39
            uv
            git
            jq
            curl
          ];

          shellHook = ''
            echo ""
            echo "🤖 AGENT: Entorno ligero listo"
            echo "🔨 Aider: Si no está instalado, corre 'uv tool install aider-chat'"
            echo "🔗 Ollama: http://localhost:11434"
            echo ""
          '';
        };
      };
    };
}
