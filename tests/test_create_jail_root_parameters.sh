#!/usr/local/bin/bash


work_dir=$(dirname "$0")

. "$work_dir/../../assert.sh/assert.sh"

. "$work_dir/lib.sh"

mkdir -p "$TEST_ROOT/does_exist"

#when called with wrong arguments, fail and display usage information

echo "**** all missing"
assert_raises "$BIN/create_jail_root" 1
assert_raises "$BIN/create_jail_root 2>&1 | grep Usage" 0
assert_end '"all missing"'

echo "**** architecture missing"
CMD="$BIN/create_jail_root -n -v -r 10.3-RELEASE  \"$TEST_ROOT/does_exist\""
assert_raises "$CMD" 0
assert_grep "$CMD" "$(uname -m)"
assert_end '"architecture missing"'

echo "**** release missing"
CMD="$BIN/create_jail_root -n -v -a amd64 \"$TEST_ROOT/does_exist\""
assert_raises "$CMD" 0
assert_grep "$CMD" "$(uname -r|grep -E -o '[0-9]+\.[0-9]+')"
assert_end '"release missing"'

echo "**** arguments checking"
CMD="$BIN/create_jail_root -n -r -a amd64 \"$TEST_ROOT/does_exist\""
assert_raises "$CMD" 1

CMD="$BIN/create_jail_root -n -r 10.3-RELEASE -a \"$TEST_ROOT/does_exist\""
assert_raises "$CMD" 1
assert_end '"arguments checking"'

echo "**** unknown parameter checking"
CMD="$BIN/create_jail_root -n -x -r 10.3-RELEASE -a amd64 \"$TEST_ROOT/does_exist\""
assert_raises "$CMD" 1
assert_grep "$CMD" "Illegal option"

assert_end '"unknown parameter checking"'



echo "**** check if target directory exists"
CMD="$BIN/create_jail_root -n -a amd64 -r 10.3-RELEASE \"$TEST_ROOT/does_not_exist\""
assert_raises "$CMD" 2
assert_raises "$CMD 2>&1 | grep 'does not exist'" 0

assert_end '"fail and display error message if target directory does not exist"'


echo "**** check if all parameters are parsed correctly"
CMD="$BIN/create_jail_root -n -v -a amd64 -r 10.3-RELEASE \"$TEST_ROOT/does_exist\""
assert_raises "$CMD" 0
assert "$CMD" "Release: 10.3-RELEASE\nArchitecture: amd64\nTarget directory: $TEST_ROOT/does_exist\nMirror: ftp://ftp.de.freebsd.org\nPackages:\n - base\n - lib32\nDry run only - not doing anything"

assert_end '"Parmeters are parsed correctly"'



