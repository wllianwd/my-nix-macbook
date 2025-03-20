{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  packages = [ pkgs.python311 pkgs.git pkgs.poetry pkgs.pyenv ];
  shellHook = ''
    echo "Checking if .venv exist"
    if [ ! -d "./.venv" ]; then
      echo "Creating python .venv"
      pyenv exec python -m venv .venv
    else
      echo "Directory .venv already exists. Skipping venv creation."
    fi

    echo "Activating venv"
    source .venv/bin/activate
    python --version && poetry env info
  '';
}
