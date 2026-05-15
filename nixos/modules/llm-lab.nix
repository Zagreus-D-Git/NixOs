{ pkgs }:
let
  cuda = pkgs.cudaPackages_12;
  python = pkgs.python312;
  pyPkgs = python.pkgs;
in {
  llm-lab = pkgs.mkShell {
    name = "llm-lab";
    packages = with pkgs; [
      python uv git
      cuda.cudatoolkit cuda.cudnn
      pyPkgs.torchWithCuda
      pyPkgs.torchvision
      pyPkgs.torchaudio
      pyPkgs.numpy
      aider-chat ollama
      nvtopPackages.full
    ];
    shellHook = ''
      export CUDA_PATH=${cuda.cudatoolkit}
      export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:${cuda.cudatoolkit}/lib:${cuda.cudnn}/lib:/run/opengl-driver/lib
      echo "🚀 LAB listo - $(python --version) - torch $(python -c 'import torch; print(torch.__version__)')"
    '';
  };

  agent = pkgs.mkShell {
    name = "agent-shell";
    packages = with pkgs; [ python312 uv aider-chat ollama sqlite ];
    shellHook = ''
      export OLLAMA_API_BASE=http://127.0.0.1:11434
      echo "🤖 agent listo"
    '';
  };
}
