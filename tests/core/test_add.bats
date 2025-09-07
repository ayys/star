#!/usr/bin/env bats

load ../helpers/helper_setup
load ../helpers/assertions

setup() { setup_tmpdir; }
teardown() { teardown_tmpdir; }

@test "adding bookmark without name uses basename" {
  skip "not implemented yet"
}

@test "conflicting basename resolves to parent/basename" {
  skip "not implemented yet"
}

@test "numeric-only name gets dir- prefix" {
  skip "not implemented yet"
}

@test "whitespace in name replaced with dash" {
  skip "not implemented yet"
}
