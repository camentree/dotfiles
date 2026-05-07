#!/bin/bash
set -e

# ============================================================
# First-time Nix setup for a new Mac
#
# Usage:
#   1. Clone this repo:  git clone git@github.com:camentree/dotfiles.git ~/Projects/dotfiles
#   2. Run:              cd ~/Projects/dotfiles && bash setup.sh <machine-name>
#   3. Restart terminal
#   4. Run:              nix-rebuild <machine-name>
#
# After that, just use `nix-rebuild <machine-name>` whenever you change config.
# ============================================================

THIS_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
HOST="${1:-server}"

echo "=============================="
echo " Nix setup for: $HOST"
echo "=============================="

# ----------------------------------------------------------
# Step 1: Install Nix (if not already installed)
# ----------------------------------------------------------
echo -e "\n[1/6] Nix"
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
echo -e "\n[2/6] Preparing /etc files for nix-darwin"
for f in /etc/bashrc /etc/zshrc; do
  if [ -f "$f" ] && ! grep -q "nix-darwin" "$f" 2>/dev/null; then
    echo "Moving $f to ${f}.before-nix-darwin"
    sudo mv "$f" "${f}.before-nix-darwin"
  fi
done

# ----------------------------------------------------------
# Step 3: SSH key (if not already set up)
# ----------------------------------------------------------
echo -e "\n[3/6] SSH key"
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
echo -e "\n[4/6] Building nix-darwin config ($HOST)"
cd "$THIS_DIR"
sudo "$(which nix 2>/dev/null || echo /nix/var/nix/profiles/default/bin/nix)" \
  --extra-experimental-features "nix-command flakes" \
  run nix-darwin -- switch --flake ".#${HOST}"

# Pick up newly installed packages from nix
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"

# ----------------------------------------------------------
# Step 5: Install runtimes via mise (node, java, sbt)
# ----------------------------------------------------------
echo -e "\n[5/6] Runtimes via mise"
if command -v mise &> /dev/null; then
  echo "Installing Node LTS..."
  mise use --global node@lts

  echo "Installing Java (temurin-17)..."
  mise use --global java@temurin-17.0.16+8

  echo "Installing sbt..."
  mise use --global sbt@1.12.5
fi

# ----------------------------------------------------------
# Step 6: Claude Code machine-specific settings (env vars for Java/sbt)
# ----------------------------------------------------------
echo -e "\n[6/6] Claude Code machine settings"
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
echo "  2. See MANUAL_SETUP.md for what still needs manual setup"
echo "  3. Use 'nix-rebuild $HOST' after any config change"
