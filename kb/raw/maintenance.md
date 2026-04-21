# NixOS Laboratory Maintenance Playbook
> Vivobook M6501RR - Kairologic Labs
> Ubicación: /kb/raw/maintenance.md
> Última actualización: 2026-04-20

## Principio
Reproducibilidad > velocidad. Cada cambio pasa por: **lock → build → test → commit → switch**.

---

## 1. Flujo diario (desarrollo de agentes)

```bash
cd ~/nixos-config

# 1. Edita .nix
nano nixos/modules/dev-agent/default.nix

# 2. Verifica sintaxis sin construir
nix flake check

# 3. Construye en sandbox (no activa)
nixos-rebuild build --flake .#vivobook-lab

# 4. Si build OK, commit
git add -A
git commit -m "feat: descripción corta"

# 5. Activa
sudo nixos-rebuild switch --flake .#vivobook-lab
```

**Por qué así**: `build` detecta errores sin romper el sistema en uso.

---

## 2. Flujo semanal (actualización de nixpkgs)

```bash
# 1. Ver estado actual
nix flake metadata | grep nixpkgs

# 2. Actualiza solo nixpkgs (no todo)
nix flake lock --update-input nixpkgs

# 3. Revisa qué cambió
git diff flake.lock

# 4. Build de prueba
nixos-rebuild build --flake .#vivobook-lab 2>&1 | tee build.log

# 5. Si falla, rollback del lock
git checkout HEAD -- flake.lock

# 6. Si OK, commit + switch
git add flake.lock
git commit -m "chore: bump nixpkgs $(date +%F)"
sudo nixos-rebuild switch --flake .#vivobook-lab
```

**Nunca uses `nix flake update` a ciegas** en unstable: actualiza todos los inputs y puede traer Python 3.13, kernel nuevo, etc.

---

## 3. Por qué `nixos-rebuild` tarda tras `flake update`

1. **Nuevo narHash**: cada paquete en nixpkgs tiene hash distinto → invalida caché local.
2. **Descarga**: ~1-5 GiB de binarios nuevos desde cache.nixos.org.
3. **Recompilación**: paquetes como `chromadb`, `python312Packages` no están pre-compilados para tu combinación → compila Rust/C++ local.
4. **Closure**: el sistema completo se re-evalúa (58 derivations en tu último log).

Es normal. La primera vez es lenta; las siguientes usan la caché.

---

## 4. Higiene de Git

```bash
# .gitignore recomendado
echo "result*" >> .gitignore
echo "*.log" >> .gitignore
echo "kb/tools/*" >> .gitignore

# script deploy (ya lo tienes)
~/nixos-config/deploy.sh
```

---

## 5. Rollback de emergencia

```bash
# lista generaciones
sudo nix-env -p /nix/var/nix/profiles/system --list-generations

# vuelve a la anterior
sudo nixos-rebuild switch --rollback
# o a una específica
sudo /nix/var/nix/profiles/system-42-link/bin/switch-to-configuration switch
```

---

## 6. Limpieza mensual

```bash
# borra generaciones >30 días
sudo nix-collect-garbage -d --delete-older-than 30d

# optimiza store (deduplica)
nix-store --optimise
```

Mantén el store <70% del SSD para evitar builds lentos.
