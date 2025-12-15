#!/bin/bash

install_env() {
  ENV="$1"
  sudo mkdir -p /var/www/flumip_${ENV}
  # download and extract the latest build
  sudo cp flumip_${ENV}.service /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable flumip_${ENV}
  echo "Setup complete for $ENV."
}

if [[ "$1" == "--prod" ]]; then
  install_env "production"
elif [[ "$1" == "--staging" ]]; then
  install_env "staging"
elif [[ -z "$1" ]]; then
  install_env "production"
  install_env "staging"
else
  echo "Usage: $0 [--prod | --staging]"
  exit 1
fi