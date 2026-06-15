#!/usr/bin/env bash
# Bootstrap a minimal Debian-family install (Debian/Ubuntu/WSL/Pop!/Mint…)
# into the hm-foreign home-manager config.
# Run once as a regular user with sudo privileges.
#
# One-liner install:
#   curl -fsSL https://raw.githubusercontent.com/Marauder586/nixos-config/main/bootstrap-hm-foreign.sh | bash
#
# (Use `bash`, not `sh` — Debian's /bin/sh is dash and won't accept `[[`,
# `$EUID`, etc.)
set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
step()  { echo -e "\n${GREEN}==> $*${NC}"; }
warn()  { echo -e "${YELLOW} !  $*${NC}"; }
die()   { echo -e "${RED}ERR $*${NC}" >&2; exit 1; }
# Read prompts from /dev/tty so they work when the script itself is being
# piped in via `curl ... | bash` (in which case stdin is the pipe, not the
# terminal, and a bare `read` would consume the rest of the script).
pause() { echo -e "\n${YELLOW}$*${NC}"; read -rp "    Press Enter to continue..." </dev/tty; }

[[ $EUID -eq 0 ]] && die "Run as a regular user, not root."

# ── 1. Apt dependencies ──────────────────────────────────────────────────────
step "Installing apt dependencies..."
sudo apt-get update -qq
sudo apt-get install -y \
  curl \
  dconf-cli \
  dconf-service \
  dbus-user-session \
  xz-utils \
  git \
  ca-certificates \
  openssh-client \
  unzip \
  wget

# ── 2. Nix (Determinate Systems installer) ───────────────────────────────────
step "Installing Nix..."
if command -v nix &>/dev/null; then
  warn "Nix already installed — skipping."
else
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
fi

# Source nix into this shell session
NIX_PROFILE=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
if [[ -e $NIX_PROFILE ]]; then
  # shellcheck source=/dev/null
  . "$NIX_PROFILE"
else
  die "Nix profile script not found — installation may have failed."
fi

# Enable flakes and nix-command for this user
mkdir -p ~/.config/nix
if ! grep -q 'experimental-features' ~/.config/nix/nix.conf 2>/dev/null; then
  echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
fi

# ── 3. SSH key ────────────────────────────────────────────────────────────────
step "Setting up SSH key..."
mkdir -p ~/.ssh && chmod 700 ~/.ssh

if [[ -f ~/.ssh/id_ed25519 ]]; then
  warn "SSH key already exists at ~/.ssh/id_ed25519 — skipping generation."
else
  ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f ~/.ssh/id_ed25519 -N ""
  echo -e "\n${GREEN}Generated new SSH key.${NC}"
fi

echo ""
read -rp "Will this host push changes back to nixos-config? [y/N] " push_access </dev/tty
push_access=${push_access,,}

if [[ $push_access == y* ]]; then
  echo ""
  echo "────────────────────────────────────────────────"
  echo "  Public key:"
  echo ""
  cat ~/.ssh/id_ed25519.pub
  echo ""
  echo "  Add it to GitHub: https://github.com/settings/ssh/new"
  echo "────────────────────────────────────────────────"

  pause "Add the key to GitHub, then press Enter."

  step "Testing GitHub SSH connection..."
  ssh -T git@github.com -o StrictHostKeyChecking=accept-new 2>&1 \
    | grep -q "successfully authenticated" \
    || warn "Could not confirm GitHub auth — continuing anyway. Check your key if the clone fails."

  clone_url="git@github.com:Marauder586/nixos-config.git"
else
  warn "Skipping GitHub key setup — cloning read-only over HTTPS."
  clone_url="https://github.com/Marauder586/nixos-config.git"
fi

# ── 4. Clone nixos-config ────────────────────────────────────────────────────
step "Cloning nixos-config..."
if [[ -d ~/nixos-config/.git ]]; then
  warn "~/nixos-config already exists — skipping clone."
else
  git clone "$clone_url" ~/nixos-config
fi

# ── 5. Build hm-foreign home-manager config ─────────────────────────────────
# --impure is required: the flake reads $USER / $HOME at eval time so a
# single output adapts to whatever login the host happens to use.
step "Building home-manager config (this will take a while on first run)..."
nix run github:nix-community/home-manager/release-26.05 -- \
  switch --flake ~/nixos-config#hm-foreign --impure

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}Bootstrap complete.${NC}"
echo "Start a new shell (or run: exec \$SHELL) to load the full environment."
