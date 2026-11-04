#!/bin/bash
# Removes Moat's system lock. Refuses while a block is running.
# Run: sudo bash uninstall.sh
set -e

if [[ $EUID -ne 0 ]]; then
  echo "Run it with sudo: sudo bash $0"
  exit 1
fi

if [[ -x /usr/local/lib/moat/moat-helper ]]; then
  /usr/local/lib/moat/moat-helper --uninstall
fi

systemctl disable --now moat.timer moat.path 2>/dev/null || true
rm -f /etc/systemd/system/moat.{service,timer,path}
systemctl daemon-reload
rm -rf /usr/local/lib/moat /etc/moat /var/lib/moat
echo "Moat system lock removed."
