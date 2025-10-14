#!/usr/bin/env bats

load ../helpers/helper_setup

setup() { setup_common; }
teardown() { teardown_common; }

@test "star remove - requires at least one argument" {
  run star remove
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}

@test "star remove - remove deletes a bookmark" {
  star add . bar

  run star remove bar
  [ "$status" -eq 0 ]
  [[ ! -L "$_STAR_HOME/$_STAR_STARS_DIR/bar" ]]
}

@test "star remove - remove multiple bookmarks at once" {
  mkdir "$TEST_ROOT/foo"
  mkdir "$TEST_ROOT/bar"
  mkdir "$TEST_ROOT/foobar"

  star add "$TEST_ROOT/foo"
  star add "$TEST_ROOT/bar"
  star add "$TEST_ROOT/foobar"

  run star remove foo foobar bar
  [ "$status" -eq 0 ]
  [[ ! -L "$_STAR_HOME/$_STAR_STARS_DIR/foo" ]]
  [[ ! -L "$_STAR_HOME/$_STAR_STARS_DIR/bar" ]]
  [[ ! -L "$_STAR_HOME/$_STAR_STARS_DIR/foobar" ]]
}

@test "star remove - cannot remove a star that does not exist" {
  star add . bar

  run star remove foo
  [ "$status" -ne 0 ]
  [[ "$output" == *"Could not find"* ]]
}

@test "star remove - cannot remove if they are no starred directories" {
  run star remove foo
  [ "$status" -ne 0 ]
  [[ "$output" == *"no starred directories"* ]]

  star add . bar
  star remove bar

  run star remove bar
  [ "$status" -ne 0 ]
  [[ "$output" == *"no starred directories"* ]]
}