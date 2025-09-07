
setup_tmpdir() {
  export TEST_ROOT="$(mktemp -d)"
  export STAR_HOME="$TEST_ROOT/.star"
  export PATH="$(pwd)/bin:$PATH"
}

teardown_tmpdir() {
  rm -rf "$TEST_ROOT"
}
