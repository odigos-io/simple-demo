#!/bin/sh
set -e

# Create odigos user for consistency with other Odigos demo packages
getent passwd odigos >/dev/null || useradd --system --user-group --no-create-home --shell /sbin/nologin odigos

# Optional: add Ondřej Sury’s PHP PPA on older hosts (Ubuntu 22.04, Debian 11).
if command -v apt-get >/dev/null 2>&1 && command -v lsb_release >/dev/null 2>&1; then
  codename=$(lsb_release -c -s)
  case "$codename" in
    jammy|bullseye)
      if ! grep -q 'ppa.launchpad.net/ondrej/php' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        apt-get update
        apt-get install -y software-properties-common
        add-apt-repository -y ppa:ondrej/php
      fi
      ;;
  esac
fi
