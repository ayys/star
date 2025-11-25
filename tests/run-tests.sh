#!/usr/bin/env bash
set -euo pipefail

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $script_dir

pushd .. &> /dev/null
export PATH="$PWD/bin:$PATH"
popd &> /dev/null

echo "Running core tests."
bats core

echo "Running integration tests."
bats integration

echo "Running environment variables tests."
bats envvars

echo "Running performance tests."
bats perf

