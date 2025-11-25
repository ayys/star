# Custom assertions for bats

assert_file_contains() {
  local file="$1"
  local expected="$2"
  grep -qF "$expected" "$file" || {
    echo "Expected '$file' to contain: $expected"
    return 1
  }
}
