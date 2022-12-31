#!/bin/bash
# shellcheck disable=SC1091

current_dir="$(dirname "${BASH_SOURCE[0]}")"

if [ "$(echo "$RUBY_MINOR" | awk '{print ($1 >= "3.2") ? "true" : "false"}')" = "true" ]; then
  source "$current_dir/openssl_3.sh"
else
  source "$current_dir/openssl_1_1.sh"
fi
