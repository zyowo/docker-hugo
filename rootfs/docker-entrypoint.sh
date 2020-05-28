#!/bin/sh
#shellcheck shell=ash
set -euo pipefail

# If any arguments were passed, run hugo directly with them
if [ $# -ge 1 ]; then
  exec ctutil run -p hugo -- hugo "${@}"
fi

# Check if a site configuration exists, otherwise create a new one
if [ ! -f /cts/hugo/persistent/data/config.toml ]; then
  ctutil log "no config.toml found, generating empty page..."
  ctutil run -p hugo -- hugo new site .
fi

# Run hugo to serve the site
exec ctutil run -p hugo -- hugo server \
  --bind="::" \
  --cacheDir="/tmp" \
  --config="/etc/hugo-docker.toml,config.toml"
