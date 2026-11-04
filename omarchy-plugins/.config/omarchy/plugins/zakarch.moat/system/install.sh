#!/bin/bash
# Installs Moat's system lock: a root timer that applies your schedule to /etc/hosts.
# Run from your own user: sudo bash install.sh
set -e

if [[ $EUID -ne 0 || -z $SUDO_USER || $SUDO_USER == root ]]; then
  echo "Run it with sudo from your own user: sudo bash $0"
  exit 1
fi

here=$(cd "$(dirname "$0")" && pwd)
home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
wants="$home/.local/state/omarchy/zakarch.moat.json"

# The helper is copied so root never runs a file the user can edit.
install -Dm755 "$here/moat-helper" /usr/local/lib/moat/moat-helper
install -dm755 /etc/moat /var/lib/moat

# Keep existing rules: reinstalling must not reset a running block.
if [[ ! -f /etc/moat/config.json ]]; then
  python3 -c 'import json, sys; print(json.dumps({"wants": sys.argv[1], "sites": [], "blocks": []}, indent=2))' "$wants" > /etc/moat/config.json
fi

cat > /etc/systemd/system/moat.service <<EOF
[Unit]
Description=Moat site blocker

[Service]
Type=oneshot
ExecStart=/usr/local/lib/moat/moat-helper
EOF

cat > /etc/systemd/system/moat.timer <<EOF
[Unit]
Description=Moat schedule check

[Timer]
OnBootSec=5s
OnUnitActiveSec=20s
AccuracySec=1s

[Install]
WantedBy=timers.target
EOF

# Applies rule changes and pass requests right away instead of on the next tick.
cat > /etc/systemd/system/moat.path <<EOF
[Unit]
Description=Moat rule changes

[Path]
PathChanged=$wants

[Install]
WantedBy=paths.target
EOF

systemctl daemon-reload
systemctl enable --now moat.timer moat.path
systemctl start moat.service
echo "Moat system lock installed."
