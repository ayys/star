#!/usr/bin/env bats

load ../helpers/helper_setup

setup() { setup_common; }
teardown() { teardown_common; }

@test "star reset - cannot reset if they are no starred directories" {
  run star reset
  [ "$status" -ne 0 ]
  [[ "$output" == *"no starred directories"* ]]

  star add . bar
  star remove bar

  run star reset
  [ "$status" -ne 0 ]
  [[ "$output" == *"no starred directories"* ]]
}

@test "star reset - abort reset on default input (pressing enter)" {
  mkdir "$TEST_ROOT/foo"
  mkdir "$TEST_ROOT/bar"

  star add "$TEST_ROOT/foo"
  star add "$TEST_ROOT/bar"


  output=$(printf "\n" | star reset 2>&1)
  status=$?
  [ "$status" -eq 0 ]
  [[ "$output" == *"Remove all starred directories"* ]]
  [[ "$output" == *"Aborting reset."* ]]
  [[ -L "${CURRENT_TEST_DATA_DIR}/foo" ]]
  [[ -L "${CURRENT_TEST_DATA_DIR}/bar" ]]
}

@test "star reset - abort reset on negative answers (n/N/no)" {
  mkdir "$TEST_ROOT/foo"
  mkdir "$TEST_ROOT/bar"

  star add "$TEST_ROOT/foo"
  star add "$TEST_ROOT/bar"

  negation_words=("n" "N" "no")

  for negation in "${negation_words[@]}"; do
    output=$(printf "%s\n" "$negation" | star reset 2>&1)
    status=$?
    [ "$status" -eq 0 ]
    [[ "$output" == *"Remove all starred directories"* ]]
    [[ "$output" == *"Aborting reset."* ]]
    [[ -L "${CURRENT_TEST_DATA_DIR}/foo" ]]
    [[ -L "${CURRENT_TEST_DATA_DIR}/bar" ]]
  done
}

@test "star reset - removes all bookmarks on positive answers (y/Y/yes)" {
  mkdir "$TEST_ROOT/foo"
  mkdir "$TEST_ROOT/bar"

  positive_words=("y" "Y" "yes")

  for positive in "${positive_words[@]}"; do
    star add "$TEST_ROOT/foo"
    star add "$TEST_ROOT/bar"

    output=$(printf "%s\n" "$positive" | star reset 2>&1)
    status=$?
    [ "$status" -eq 0 ]
    [[ "$output" == *"Remove all starred directories"* ]]
    [[ "$output" == *"All stars have been removed."* ]]
    [[ ! -L "${CURRENT_TEST_DATA_DIR}/foo" ]]
    [[ ! -L "${CURRENT_TEST_DATA_DIR}/bar" ]]
  done
}

@test "star reset - prompt user until valid answer is provided" {
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo"

  output=$(printf "invalid1\ninvalid2\ninvalid3\nn" | star reset 2>&1)
  status=$?
  [ "$status" -eq 0 ]
  [[ $(echo "$output" | head -n 1) == *"Not a valid answer."* ]]
  [[ $(echo "$output" | head -n 2 | tail -n 1) == *"Not a valid answer."* ]]
  [[ $(echo "$output" | head -n 3 | tail -n 1) == *"Not a valid answer."* ]]
  [[ $(echo "$output" | head -n 4 | tail -n 1) == *"Aborting reset."* ]]
}

@test "star reset - reset with -f does not prompt" {
  mkdir "$TEST_ROOT/foo"
  mkdir "$TEST_ROOT/bar"

  star add "$TEST_ROOT/foo"
  star add "$TEST_ROOT/bar"

  run star reset -f
  [ "$status" -eq 0 ]
  [[ "$output" == *"All stars have been removed."* ]]
  [[ ! -L "${CURRENT_TEST_DATA_DIR}/foo" ]]
  [[ ! -L "${CURRENT_TEST_DATA_DIR}/bar" ]]
}
