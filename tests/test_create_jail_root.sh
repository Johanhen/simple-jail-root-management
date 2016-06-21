#!/usr/local/bin/bash

. ../../assert.sh/assert.sh

TEST_ROOT=/var/tmp/root_creation_tests
BIN=../src


function assert_grep () {
	cmd=$1
	shift
	output=$(eval $cmd)

	for pattern in "$@"; do
		assert_raises "grep  -E -e \"$pattern\" <<< \"$output\"" 0
	done
}

rm -rf "$TEST_ROOT"
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


# check if all parameters are parsed correctly
mkdir "$TEST_ROOT/new_root"
CMD="$BIN/create_jail_root -n -v -a amd64 -r 10.3-RELEASE \"$TEST_ROOT/new_root\""
assert_raises "$CMD" 0
assert "$CMD" "Release: 10.3-RELEASE\nArchitecture: amd64\nTarget directory: $TEST_ROOT/new_root\nMirror: ftp://ftp.de.freebsd.org\nPackages:\n - base\n - lib32\nDry run only - not doing anything"

assert_end '"Parmeters are parsed correctly"'

FTP_DIR="ftp://ftp.de.freebsd.org/pub/FreeBSD/releases/amd64/amd64/10.3-RELEASE"

CMD="$BIN/create_jail_root -v -a amd64 -r 10.3-RELEASE \"$TEST_ROOT/new_root\""
assert_grep "$CMD" "Downloading $FTP_DIR/MANIFEST" "Downloading $FTP_DIR/base.txz" "Downloading $FTP_DIR/lib32.txz"
assert_raises "test -f /var/tmp/amd64/10.3-RELEASE/MANIFEST"
assert_raises "test -f /var/tmp/amd64/10.3-RELEASE/base.txz"
assert_raises "test -f /var/tmp/amd64/10.3-RELEASE/lib32.txz"

assert_end '"Correct package sets are downloaded"'



CMD="$BIN/create_jail_root -v -a amd64 -r 10.3-RELEASE \"$TEST_ROOT/new_root\""
assert_grep "$CMD" "Extracting base" "Extracting lib32"
assert_raises "test -f \"$TEST_ROOT/new_root/sbin/sha256\""
assert_raises "test -f \"$TEST_ROOT/new_root/usr/lib32/libc.so\""

assert_end '"Packages have been extracted"'




