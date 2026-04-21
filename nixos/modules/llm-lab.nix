{ pkgs }:
let cuda = pkgs.cudaPackages;
in {
  llm-lab = pkgs.mkShell {
    name = "llm-lab";
    packages = with pkgs; [
      python312 uv git nvtopPackages.full
      cuda.cudatoolkit cuda.cudnn
      aider-chat ollama
      stdenv.cc.cc.lib zlib
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
    packages = with pkgs; [ python312 uv aider-chat ollama sqlite sqlite-vec ];
    shellHook = ''
      export OLLAMA_API_BASE=http://127.0.0.1:11434
      export OPENCLAW_DB=$HOME/nixos-config/kb/memory.db
      test -d .venv-agent || uv venv -p 3.12 .venv-agent
      source .venv-agent/bin/activate
      echo "🤖 agent listo"
    '';
  };
}
