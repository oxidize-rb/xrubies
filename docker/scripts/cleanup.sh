#!/bin/bash

set -euo pipefail

# shellcheck disable=SC1091
source /helpers.sh

main() {
  if_ubuntu \
    apt-get update -y -qq && \
    apt-get upgrade -y -qq && \
    purge_packages \
      vim && \
    apt-get clean -y -qq && \
    rm -rf /var/apt/lists/*

  if_centos \
    yum update -y && \
    purge_packages \
      vim && \
    yum clean all && \
    rm -rf /var/cache/yum

  rm -rf "${0}"
}

main "$@"
