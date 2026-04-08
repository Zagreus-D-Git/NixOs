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
            python311
            uv
            git
            nvtopPackages.full

            # ML stack
            python311Packages.torch-bin
            python311Packages.torchvision-bin
            python311Packages.transformers
            python311Packages.accelerate
            python311Packages.datasets
            python311Packages.sentencepiece

            # CUDA toolchain
            cudaPackages.cudatoolkit
            cudaPackages.cudnn
          ];

          shellHook = ''
            echo ""
            echo "🚀 LAB: Entorno de ML cargado"
            echo "🐍 Python: $(python311 --version)"
            echo "📟 CUDA: $(python311 -c 'import torch; print(torch.cuda.is_available())' 2>/dev/null || echo 'No detectado')"
            echo "💡 Tip: Si usas el modo on-the-go, usa 'nvidia-offload python <script>'"
            echo ""
          '';
        };

        # ── Shell de Agente (Ligero para Aider/Herramientas) ──
        # Se entra con: nix develop .#agent
        agent = pkgs.mkShell {
          name = "agent-shell";
          packages = with pkgs; [
            python311
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
