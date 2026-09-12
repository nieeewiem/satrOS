#!/usr/bin/env bash
set -euo pipefail

install -d -m 0755 /etc/calamares/modules
cp -a /root/satros-calamares/. /etc/calamares/
rm -rf /root/satros-calamares
