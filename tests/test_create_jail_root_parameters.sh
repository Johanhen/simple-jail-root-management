#!/usr/local/bin/bash


work_dir=$(dirname "$0")

. "$work_dir/../../assert.sh/assert.sh"

. "$work_dir/lib.sh"

mkdir -p "$TEST_ROOT/does_exist"

#when called with wrong arguments, fail and display usage information

begin_test "all missing"
assert_raises "$BIN/create_jail_root" 1
assert_raises "$BIN/create_jail_root 2>&1 | grep Usage" 0
end_test

begin_test "architecture missing"
CMD="$BIN/create_jail_root -n -v -r 10.3-RELEASE  \"$TEST_ROOT/does_exist\""
assert_raises "$CMD" 0
assert_grep "$CMD" "$(uname -m)"
end_test

begin_test "release missing"
CMD="$BIN/create_jail_root -n -v -a amd64 \"$TEST_ROOT/does_exist\""
assert_raises "$CMD" 0
assert_grep "$CMD" "$(uname -r|grep -E -o '[0-9]+\.[0-9]+')"
end_test

begin_test "arguments checking"
CMD="$BIN/create_jail_root -n -r -a amd64 \"$TEST_ROOT/does_exist\""
assert_raises "$CMD" 1

CMD="$BIN/create_jail_root -n -r 10.3-RELEASE -a \"$TEST_ROOT/does_exist\""
assert_raises "$CMD" 1
end_test

begin_test "unknown parameter checking"
CMD="$BIN/create_jail_root -n -x -r 10.3-RELEASE -a amd64 \"$TEST_ROOT/does_exist\""
assert_raises "$CMD" 1
assert_grep "$CMD" "Illegal option"

end_test



begin_test "check if target directory exists"
CMD="$BIN/create_jail_root -n -a amd64 -r 10.3-RELEASE \"$TEST_ROOT/does_not_exist\""
assert_raises "$CMD" 2
assert_raises "$CMD 2>&1 | grep 'does not exist'" 0

end_test

begin_test "check if files to copy exist"
CMD="$BIN/create_jail_root -n -f /etc/localtime,/etc/does_not_exist \"$TEST_ROOT/does_exist\""
assert_raises "$CMD" 1
assert_grep "$CMD 2>&1" 'File /etc/does_not_exist should be copied to new root but does not exist or is not readable'
end_test



begin_test "file list can be empty"
CMD="$BIN/create_jail_root -n -f '' \"$TEST_ROOT/does_exist\""
assert_raises "$CMD" 0
end_test

begin_test "package list must not be empty"
CMD="$BIN/create_jail_root -n -p '' \"$TEST_ROOT/does_exist\""
assert_raises "$CMD" 1
end_test



begin_test "check if all parameters are parsed correctly"
CMD="$BIN/create_jail_root -n -v -a amd64 -r 10.3-RELEASE -p base,lib32 -f /etc/localtime,/etc/resolv.conf,/etc/hosts \"$TEST_ROOT/does_exist\""
assert_raises "$CMD" 0
assert_grep "$CMD" "Release: 10.3-RELEASE" \
	"Architecture: amd64" \
	"Target directory: $TEST_ROOT/does_exist" \
	"Mirror: ftp://ftp.de.freebsd.org" \
	"Packages:" \
	" - base" \
	" - lib32" \
	"Files to copy:" \
	" - /etc/localtime" \
	" - /etc/resolv.conf" \
	" - /etc/hosts" \
	"Dry run only - not doing anything"

end_test



