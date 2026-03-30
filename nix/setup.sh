#!/bin/bash
set -e

# ============================================================
# First-time Nix setup for a new Mac
#
# Usage:
#   1. Clone this repo:  git clone git@github.com:camentree/dotfiles.git ~/Projects/dotfiles
#   2. Run:              cd ~/Projects/dotfiles && bash setup.sh
#   3. Restart terminal
#   4. Run:              rebuild
#
# After that, just use `rebuild` whenever you change config.
# ============================================================

THIS_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
HOST="${1:-server}"

echo "=============================="
echo " Nix setup for: $HOST"
echo "=============================="

# ----------------------------------------------------------
# Step 1: Install Nix (if not already installed)
# ----------------------------------------------------------
echo -e "\n[1/5] Nix"
if command -v nix &> /dev/null; then
  echo "Already installed: $(nix --version)"
else
  echo "Installing Nix..."
  echo "This will ask for your sudo password."
  sh <(curl -L https://nixos.org/nix/install) --daemon
  echo ""
  echo "Nix installed. Please restart your terminal and run this script again."
  exit 0
fi

# ----------------------------------------------------------
# Step 2: Move conflicting /etc files (nix-darwin needs these)
# ----------------------------------------------------------
echo -e "\n[2/5] Preparing /etc files for nix-darwin"
for f in /etc/bashrc /etc/zshrc; do
  if [ -f "$f" ] && ! grep -q "nix-darwin" "$f" 2>/dev/null; then
    echo "Moving $f to ${f}.before-nix-darwin"
    sudo mv "$f" "${f}.before-nix-darwin"
  fi
done

# ----------------------------------------------------------
# Step 3: SSH key (if not already set up)
# ----------------------------------------------------------
echo -e "\n[3/5] SSH key"
if [ -f "$HOME/.ssh/id_ed25519" ]; then
  echo "Already exists"
else
  echo "Generating ed25519 SSH key..."
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N ""
  echo ""
  echo "Add this key to GitHub: https://github.com/settings/keys"
  echo ""
  cat "$HOME/.ssh/id_ed25519.pub"
  echo ""
  read -p "Press Enter after you've added the key to GitHub..."
fi

# ----------------------------------------------------------
# Step 4: Build and activate
# ----------------------------------------------------------
echo -e "\n[4/5] Building nix-darwin config ($HOST)"
cd "$THIS_DIR"
sudo "$(which nix 2>/dev/null || echo /nix/var/nix/profiles/default/bin/nix)" \
  --extra-experimental-features "nix-command flakes" \
  run nix-darwin -- switch --flake ".#${HOST}"

# ----------------------------------------------------------
# Step 5: Install Node via mise (nvm replacement)
# ----------------------------------------------------------
echo -e "\n[5/5] Node.js via mise"
if command -v mise &> /dev/null; then
  if mise ls node 2>/dev/null | grep -q "lts"; then
    echo "Node LTS already installed"
  else
    echo "Installing Node LTS..."
    mise use --global node@lts
  fi
fi

echo ""
echo "=============================="
echo " Done!"
echo "=============================="
echo ""
echo "Next steps:"
echo "  1. Restart your terminal"
echo "  2. Type 'rebuild' after any config change"
echo "  3. See NIX_GUIDE.md for how everything works"
echo "  4. See README.md for what still needs manual setup"
