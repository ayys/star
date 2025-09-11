
setup_tmpdir() {
  export TEST_ROOT="$(mktemp -d)"
  export TEST_STAR_DIR="$TEST_ROOT/.star"

  star_script="star_2_0_0.bash"
  # copy and patch the star script

  sed "s|^STAR_DIR=.*|STAR_DIR=\"$STAR_DIR\"|" "$star_script" > "$TEST_ROOT/$star_script"

  source "$TEST_ROOT/$star_script"
}

teardown_tmpdir() {
  rm -rf "$TEST_ROOT"
}
