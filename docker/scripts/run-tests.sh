#!/bin/bash

set -euo pipefail

run_tests_for_version() {
  echo "🧪 Running tests for $1" >&2

  "$1/bin/gem" install minitest
  "$1/bin/ruby" /tests.rb
  "$1/bin/gem" uninstall minitest
}

main() {
  export GEM_HOME
  GEM_HOME="$(mktemp -d)"

  for ruby_install_dir in /opt/xrubies/*/; do
    echo "🧪 Running tests for $ruby_install_dir" >&2
    run_tests_for_version "$ruby_install_dir"
  done

  rm -rf "$GEM_HOME" "${0}" /tests.rb
}

main "$@"
