#!/usr/local/bin/bash

. ../../assert.sh/assert.sh

TEST_ROOT=/var/tmp/root_creation_tests
BIN=../src

mkdir -p "$TEST_ROOT"

#when called with wrong arguments, fail and display usage information

# all missing
assert_raises "$BIN/create_jail_root" 1
assert_raises "$BIN/create_jail_root 2>&1 | grep Usage" 0

# architecture missing
CMD="$BIN/create_jail_root -r 10.3-RELEASE  \"$TEST_ROOT/does_not_exist\""
assert_raises "$CMD" 1
assert_raises "$CMD 2>&1 | grep \"No architecture specified\"" 0

# release missing
CMD="$BIN/create_jail_root -a amd64 \"$TEST_ROOT/does_not_exist\""
assert_raises "$CMD" 1
assert_raises "$CMD 2>&1 | grep \"No release specified\"" 0

# arguments checking
CMD="$BIN/create_jail_root -r -a amd64 \"$TEST_ROOT/does_not_exist\""
assert_raises "$CMD" 1

CMD="$BIN/create_jail_root -r 10.3-RELEASE -a \"$TEST_ROOT/does_not_exist\""
assert_raises "$CMD" 1

# unknown parameter checking
CMD="$BIN/create_jail_root -x -r 10.3-RELEASE -a amd64 \"$TEST_ROOT/does_not_exist\""
assert_raises "$CMD" 1
assert_raises "$CMD 2>&1 | grep \"Illegal option\"" 0

assert_end '"fail and display usage if parameters wrong"'


# check if target directory exists
CMD="$BIN/create_jail_root -a amd64 -r 10.3-RELEASE \"$TEST_ROOT/does_not_exist\""
assert_raises "$CMD" 2
assert_raises "$CMD 2>&1 | grep 'does not exist'" 0

assert_end '"fail and display error message if target directory does not exist"'




