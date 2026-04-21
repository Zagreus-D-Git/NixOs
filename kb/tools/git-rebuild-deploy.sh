cat > ~/nixos-config/git-rebuild-deploy.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd /home/zagreus/nixos-config

# 1. commit automático solo si hay cambios
if ! git diff --quiet || ! git diff --cached --quiet; then
  git add -A
  git commit -m "auto-deploy $(date +%F_%H:%M)"
fi

# 2. rebuild
sudo nixos-rebuild switch --flake .#vivobook-lab
EOF
chmod +x ~/nixos-config/git-rebuild-deploy.sh
