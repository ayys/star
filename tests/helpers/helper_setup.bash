
load ../helpers/helper_log

detect_shell_type() {
  if [ -n "$BASH_VERSION" ]; then
    echo "bash"
  elif [ -n "$ZSH_VERSION" ]; then
    echo "zsh"
  else
    echo "unknown"
  fi
}

setup_tmpdir() {
  export TEST_ROOT="$(realpath "$(mktemp -d)")"
}

teardown_tmpdir() {
  rm -rf "$TEST_ROOT"
}

setup_common() {
  local current_shell_type
  current_shell_type="$(detect_shell_type)"

  if [[ "$current_shell_type" == "unknown" ]]; then
    echo "Error: could not determine shell type." >&2
    return 1
  fi

  # create tmp dir and set $TEST_ROOT
  setup_tmpdir

  export PATH="$PWD/bin:$PATH"
  export _STAR_DATA_HOME=$TEST_ROOT

  export _STAR_LIST_FORMAT="<INDEX>: ${_STAR_COLOR_STAR}%f${_STAR_COLOR_RESET} -> ${_STAR_COLOR_PATH}%l${_STAR_COLOR_RESET}"
  export _STAR_EXPORT_ENV_VARIABLES=yes
  # export _STAR_LIST_FORMAT="${_STAR_COLOR_STAR}%f${_STAR_COLOR_RESET} -> ${_STAR_COLOR_PATH}%l${_STAR_COLOR_RESET}"
  # export _STAR_EXPORT_ENV_VARIABLES=no

  export CURRENT_TEST_DATA_DIR="${_STAR_DATA_HOME}/stars"

  # load star function
  eval "$(command star init "${current_shell_type}")"
}

teardown_common() {
  if [ "$BATS_TEST_COMPLETED" != "1" ]; then
    echo
    echo "========================================"
    echo "Test '${BATS_TEST_NAME}' failed. Debugging:"
    echo "----------"
    log_variable status
    echo "----------"
    log_variable output
    echo "----------"
    tree -a "$TEST_ROOT"
    echo "----------"
    find "${_STAR_DATA_HOME}/stars" -type l -not -xtype l -printf "%As %f %l\n"
    echo "========================================"
    echo
  fi

  teardown_tmpdir
}
