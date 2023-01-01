#!/usr/bin/env bash

# shellcheck disable=SC2294
# shellcheck disable=SC1091

source /lib.sh

purge_list=()

install_packages() {
  if grep -i ubuntu /etc/os-release; then
    apt-get update -y -qq

    local to_install
    to_install=()

    for pkg in "${@}"; do
      if ! dpkg -L "${pkg}" >/dev/null 2>/dev/null; then
        to_install+=( "${pkg}" )
        purge_list+=( "${pkg}" )
      fi
    done

    apt-get install -y -qq --no-install-recommends "${to_install[@]}"
  else
    set_centos_ulimit

    for pkg in "${@}"; do
      if ! yum list installed "${pkg}" >/dev/null 2>/dev/null; then
        yum install -y "${pkg}"

        purge_list+=( "${pkg}" )
      fi
    done
  fi
}

purge_packages() {
  if (( ${#purge_list[@]} )); then
    if grep -i ubuntu /etc/os-release; then
      apt-get purge -qq --assume-yes --auto-remove "${purge_list[@]}"
      rm -rf /var/apt/lists/*
    else
      yum remove -y "${purge_list[@]}"
    fi
  fi
}

if_centos() {
  if grep -q -i centos /etc/os-release; then
    eval "${@}"
  fi
}

if_ubuntu() {
  if grep -q -i ubuntu /etc/os-release; then
    eval "${@}"
  fi
}
