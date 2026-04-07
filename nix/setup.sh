#!/bin/bash
set -e

# ============================================================
# First-time Nix setup for a new Mac
#
# Usage:
#   1. Clone this repo:  git clone git@github.com:camentree/dotfiles.git ~/Projects/dotfiles
#   2. Run:              cd ~/Projects/dotfiles/nix && bash setup.sh <machine-name>
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
echo -e "\n[1/8] Nix"
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
echo -e "\n[2/8] Preparing /etc files for nix-darwin"
for f in /etc/bashrc /etc/zshrc; do
  if [ -f "$f" ] && ! grep -q "nix-darwin" "$f" 2>/dev/null; then
    echo "Moving $f to ${f}.before-nix-darwin"
    sudo mv "$f" "${f}.before-nix-darwin"
  fi
done

# ----------------------------------------------------------
# Step 3: SSH key (if not already set up)
# ----------------------------------------------------------
echo -e "\n[3/8] SSH key"
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
echo -e "\n[4/8] Building nix-darwin config ($HOST)"
cd "$THIS_DIR"
sudo "$(which nix 2>/dev/null || echo /nix/var/nix/profiles/default/bin/nix)" \
  --extra-experimental-features "nix-command flakes" \
  run nix-darwin -- switch --flake ".#${HOST}"

# Pick up newly installed packages from nix
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"

# ----------------------------------------------------------
# Step 5: Install runtimes via mise (node, java, sbt)
# ----------------------------------------------------------
echo -e "\n[5/8] Runtimes via mise"
if command -v mise &> /dev/null; then
  echo "Installing Node LTS..."
  mise use --global node@lts

  echo "Installing Java (temurin-17)..."
  mise use --global java@temurin-17.0.16+8

  echo "Installing sbt..."
  mise use --global sbt@1.12.5
fi

# ----------------------------------------------------------
# Step 6: Global npm packages
# ----------------------------------------------------------
echo -e "\n[6/8] Global npm packages"
if command -v mise &> /dev/null; then
  eval "$(mise activate bash)"
  for pkg in typescript eslint; do
    if ! npm list -g --depth=0 "$pkg" &> /dev/null 2>&1; then
      echo "Installing $pkg..."
      npm install -g "$pkg"
    else
      echo "$pkg already installed globally"
    fi
  done
fi

# ----------------------------------------------------------
# Step 7: Base Python virtual environment
# ----------------------------------------------------------
echo -e "\n[7/8] Base Python virtual environment"
VENV_DIR="$HOME/.venvs/base3.13"
if [[ ! -d "$VENV_DIR" ]]; then
  echo "Creating base venv at $VENV_DIR..."
  mkdir -p "$HOME/.venvs"
  uv venv --python 3.13 "$VENV_DIR"
else
  echo "Base venv already exists"
fi

# ----------------------------------------------------------
# Step 8: Claude Code machine-specific settings
# ----------------------------------------------------------
echo -e "\n[8/8] Claude Code machine settings"
CLAUDE_LOCAL="$HOME/.claude/settings.local.json"
if [[ ! -f "$CLAUDE_LOCAL" ]]; then
  echo "Creating $CLAUDE_LOCAL..."
  mkdir -p "$HOME/.claude"
  JAVA_HOME_VAL="$HOME/.local/share/mise/installs/java/temurin-17.0.16+8"
  cat > "$CLAUDE_LOCAL" << CLAUDE_EOF
{
  "env": {
    "JAVA_HOME": "$JAVA_HOME_VAL",
    "PATH": "$JAVA_HOME_VAL/bin:$HOME/.local/share/mise/installs/sbt/1.12.5/bin:/bin:/usr/bin:/usr/sbin:/sbin:/run/current-system/sw/bin:$HOME/.local/bin"
  }
}
CLAUDE_EOF
else
  echo "Already exists"
fi

echo ""
echo "=============================="
echo " Done!"
echo "=============================="
echo ""
echo "Next steps:"
echo "  1. Restart your terminal"
echo "  2. Type 'nix-rebuild $HOST' after any config change"
echo "  3. See NIX_GUIDE.md for how everything works"
echo "  4. See MANUAL_SETUP.md for what still needs manual setup"
