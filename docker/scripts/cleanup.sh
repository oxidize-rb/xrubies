#!/bin/bash

set -euo pipefail

# shellcheck disable=SC1091
source /helpers.sh

packages_to_purge=(
  vim
)

main() {
  if is_ubuntu; then
    apt-get update -y -qq
    apt-get upgrade -y -qq
    purge_packages "${packages_to_purge[@]}"
    apt-get clean -y -qq
    rm -rf /var/apt/lists/*
  fi

  if is_centos; then
    yum update -y
    purge_packages "${packages_to_purge[@]}"
    yum clean all
    rm -rf /var/cache/yum
  fi

  rm -rf "${0}"
}

main "$@"
