
setup_common() {
  source star_2_0_0.bash
}

setup_tmpdir() {
  export TEST_ROOT="$(mktemp -d)"
  export _STAR_HOME="$TEST_ROOT/.star"

  setup_common
}

teardown_tmpdir() {
  rm -rf "$TEST_ROOT"
}
