{
  description = "LLM Agentic Lab - Vivobook RTX 3070";

  inputs = {
    # usa small para garantizar cache de CUDA
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        # NO cudaSupport aquí
      };
      cuda = pkgs.cudaPackages_12_4;
    in
    {
      devShells.${system} = {
        # ── Shell completo ML ─────────────────────────────────
        default = pkgs.mkShell {
          name = "llm-lab";
          packages = with pkgs; [
            python312
            uv
            git
            nvtopPackages.full

            # CUDA toolkit del sistema (binario, del cache)
            cuda.cudatoolkit
            cuda.cudnn
            linuxPackages.nvidia_x11 # para libcuda.so

            # herramientas
            aider-chat
            ollama
          ];

          shellHook = ''
            export CUDA_PATH=${cuda.cudatoolkit}
            export LD_LIBRARY_PATH=${cuda.cudatoolkit}/lib:${cuda.cudnn}/lib:${pkgs.linuxPackages.nvidia_x11}/lib
            export EXTRA_LDFLAGS="-L${cuda.cudatoolkit}/lib"
            export EXTRA_CFLAGS="-I${cuda.cudatoolkit}/include"

            # crea venv la primera vez
            if [ ! -d .venv ]; then
              echo "📦 Creando venv con uv..."
              uv venv -p 3.12 .venv
            fi
            source .venv/bin/activate

            # instala torch desde ruedas oficiales, NO compila
            if ! python -c "import torch" 2>/dev/null; then
              echo "⬇️  Instalando PyTorch cu124 (ruedas precompiladas)..."
              uv pip install --quiet torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
              uv pip install --quiet transformers accelerate datasets sentencepiece jupyterlab
            fi

            echo ""
            echo "🚀 LAB: Python 3.12 + CUDA 12.4"
            python -c "import torch; print(f'🔥 PyTorch {torch.__version__} | CUDA: {torch.cuda.is_available()} | GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}')"
            echo "💡 Ollama: http://127.0.0.1:11434"
            echo ""
          '';
        };

        # ── Shell ligero para agentes ─────────────────────────
        agent = pkgs.mkShell {
          name = "agent-shell";
          packages = with pkgs; [
            python312
            uv
            git jq curl
            aider-chat
            ollama
          ];

          shellHook = ''
            export OLLAMA_HOST=http://127.0.0.1:11434

            if [ ! -d .venv-agent ]; then
              uv venv -p 3.12 .venv-agent
            fi
            source .venv-agent/bin/activate

            echo ""
            echo "🤖 AGENT: Entorno ligero"
            echo "🔗 Ollama: $OLLAMA_HOST"
            echo "💡 Prueba: aider --model ollama/qwen2.5-coder:7b"
            echo "📝 Modelos disponibles:"
            ollama list 2>/dev/null | head -5
            echo ""
          '';
        };
      };
    };
}
