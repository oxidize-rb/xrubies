#!/bin/bash

set -euo pipefail

if [[ ! "$*" =~ %DOCKER_TAG% ]]; then
  echo "Error: %DOCKER_TAG% not found in args: $*" >&2
  exit 1
fi

for tag in $(echo "$DOCKER_TAGS" | jq -r '.[]'); do
  cmd="${*//\%DOCKER_TAG\%/$tag}"
  cmd="${cmd#-- }"
  echo "::group::Running $cmd"
  eval "$cmd"
  echo "::endgroup::"
done
