#!/bin/bash
# shellcheck disable=SC1091

current_dir="$(dirname "${BASH_SOURCE[0]}")"

if [[ $(echo "$RUBY_MINOR >= 3.2" | bc) == 1 ]] ; then
  source "$current_dir/openssl_3.sh"
else
  source "$current_dir/openssl_1_1.sh"
fi
