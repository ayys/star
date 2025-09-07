#!/usr/bin/env bash
set -euo pipefail

echo "Running core tests."
bats tests/core

echo "Running integration tests."
bats tests/integration

echo "Running environment variables tests."
bats tests/envvars
