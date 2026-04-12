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
            gdb lldb valgrind py-spy
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
