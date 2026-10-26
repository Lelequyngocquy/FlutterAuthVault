#!/usr/bin/env bash
# Root entrypoint redirecting to scripts/docker_run.sh
exec "$(dirname "$0")/scripts/docker_run.sh" "$@"
