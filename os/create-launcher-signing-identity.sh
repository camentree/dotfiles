#!/bin/bash
# Creates the self-signed code-signing identity that os/server.nix signs
# fda-launcher with, in the login keychain of the user running it. Run once
# per server, over ssh, as camen. Prompts once for the login password so
# codesign can use the key without a keychain dialog.
set -euo pipefail

identity_name="Parallax Launcher Signing"
keychain="$HOME/Library/Keychains/login.keychain-db"

if security find-identity -v -p codesigning "$keychain" | grep -q "$identity_name"; then
  echo "'$identity_name' already exists in $keychain"
  exit 0
fi

work_directory=$(mktemp -d)
trap 'rm -rf "$work_directory"' EXIT

cat > "$work_directory/openssl.cnf" <<EOF
[req]
distinguished_name = subject
x509_extensions = extensions
prompt = no

[subject]
CN = $identity_name

[extensions]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
subjectKeyIdentifier = hash
EOF

/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 7300 \
  -config "$work_directory/openssl.cnf" \
  -keyout "$work_directory/key.pem" \
  -out "$work_directory/certificate.pem"

/usr/bin/openssl pkcs12 -export \
  -inkey "$work_directory/key.pem" \
  -in "$work_directory/certificate.pem" \
  -out "$work_directory/identity.p12" \
  -passout pass:import

security import "$work_directory/identity.p12" -k "$keychain" -P import -T /usr/bin/codesign
sudo security add-trusted-cert -d -r trustRoot -p codeSign "$work_directory/certificate.pem"

echo "Login keychain password, so codesign can use the key unattended:"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s "$keychain"

security find-identity -v -p codesigning "$keychain" | grep "$identity_name"
echo "Done. nix-rebuild now signs ~/.local/bin/fda-launcher; then re-tick it under Full Disk Access once."
