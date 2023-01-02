#!/usr/bin/env bash

# shellcheck disable=SC2294
# shellcheck disable=SC1091

source /lib.sh

purge_list=()

install_persistent_packages() {
  old_purge_list=("${purge_list[@]}")
  install_packages "${@}"
  purge_list=("${old_purge_list[@]}")

  if grep -i ubuntu /etc/os-release; then
    apt-get clean -y -qq
    rm -rf /var/apt/lists/*
  else
    yum clean all
    rm -rf /var/cache/yum
  fi
}

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
  local to_purge

  if (( ${#purge_list[@]} )); then
    to_purge=("${purge_list[@]}")
  else
    to_purge=("${@}")
  fi

  if (( ${#to_purge[@]} )); then
    if grep -i ubuntu /etc/os-release; then
      apt-get purge -qq --assume-yes --auto-remove "${to_purge[@]}"
      rm -rf /var/apt/lists/*
    else
      yum remove -y "${to_purge[@]}"
      rm -rf /var/cache/yum
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
