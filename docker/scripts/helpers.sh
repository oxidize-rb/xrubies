#!/usr/bin/env bash

# shellcheck disable=SC2294
# shellcheck disable=SC1091

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

install_patchelf() {
  local td
  td="$(mktemp -d)"
  local cpu_type

  if [[ "$TARGET_DEB_ARCH" == "arm64" ]]; then
    cpu_type="aarch64"
  elif [[ "$TARGET_DEB_ARCH" == "amd64" ]]; then
    cpu_type="x86_64"
  else
    echo "Unsupported architecture: $TARGET_DEB_ARCH" >&2
    exit 1
  fi

  echo "Installing patchelf for $cpu_type" >&2

  local url
  url="https://github.com/NixOS/patchelf/releases/download/0.17.0/patchelf-0.17.0-$cpu_type.tar.gz"
  curl -fsSL "$url" | tar -xz -C "$td"


  mv "$td/bin/patchelf" /usr/local/bin
  rm -rf "$td"
  echo "Installed patchelf: $(patchelf --version)" >&2
}
