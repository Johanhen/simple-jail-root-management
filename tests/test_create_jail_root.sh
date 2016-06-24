#!/usr/local/bin/bash

#stop after first test failure
export STOP=1

do_setup=1
test_download=1
test_verification=1
test_extract=1
test_update=1
test_ids=1
test_copy_files=1
do_cleanup=1

work_dir=$(dirname "$0")

. "$work_dir/../../assert.sh/assert.sh"

. "$work_dir/lib.sh"

if [ $do_setup -eq 1 ]; then
	destroy_root_fs "$TEST_ROOT/new_root"
	rm -rf "$TEST_ROOT"
	mkdir -p "$TEST_ROOT"
	create_root_fs "$TEST_ROOT/new_root"
fi

if [ $test_download -eq 1 ]; then
	# check if files are downloaded correctly
	FTP_DIR="ftp://ftp.de.freebsd.org/pub/FreeBSD/releases/amd64/amd64/10.3-RELEASE"
	CMD="$BIN/create_jail_root -D -v -a amd64 -r 10.3-RELEASE -p base,lib32 \"$TEST_ROOT/new_root\""
	assert_grep "$CMD" "Downloading $FTP_DIR/MANIFEST" "Downloading $FTP_DIR/base.txz" "Downloading $FTP_DIR/lib32.txz"
	assert_raises "test -f /var/tmp/amd64/10.3-RELEASE/MANIFEST"
	assert_raises "test -f /var/tmp/amd64/10.3-RELEASE/base.txz"
	assert_raises "test -f /var/tmp/amd64/10.3-RELEASE/lib32.txz"

	assert_end '"Correct package sets are downloaded"'
fi



if [ $test_verification -eq 1 ]; then
	# check if verification works
	CMD="$BIN/create_jail_root -V -v -a amd64 -r 10.3-RELEASE -p base,lib32 \"$TEST_ROOT/new_root\""
	assert_grep "$CMD" "Verifying checksum for base.txz" "Verifying checksum for lib32.txz"
	### make verification fail
	base_pkg="/var/tmp/amd64/10.3-RELEASE/base.txz"
	cp "$base_pkg" "$base_pkg.bak"
	echo make_checksum_bad >> "$base_pkg"
	assert_raises "$CMD" 4
	### restore original file
	mv "$base_pkg.bak" "$base_pkg"
	assert_end '"Packages are verified correctly"'
fi



if [ $test_extract -eq 1 ]; then
	# Check if packages are extracted correctly
	CMD="$BIN/create_jail_root -E -v -a amd64 -r 10.3-RELEASE -p base,lib32 \"$TEST_ROOT/new_root\""

	snapshot_root_fs "$TEST_ROOT/new_root"

	### make extract fail
	cp "$base_pkg" "$base_pkg.bak"
	echo make_file_corrupt >> "$base_pkg"
	assert_raises "$CMD" 5
	### restore original file
	mv "$base_pkg.bak" "$base_pkg"

	rollback_root_fs "$TEST_ROOT/new_root"

	assert_grep "$CMD" "Extracting base" "Extracting lib32"
	assert_raises "test -f \"$TEST_ROOT/new_root/sbin/sha256\""
	assert_raises "test -f \"$TEST_ROOT/new_root/usr/lib32/libc.so\""
	assert_end '"Packages have been extracted"'
fi



if [ $test_update -eq 1 ]; then
	# make sure architecture is saved
	assert "cat \"$TEST_ROOT/new_root/etc/jail_architecture\"" "amd64"
	assert_end '"Architecture has been stored in /etc/jail_architecture"'

	# make sure FreeBSD update is run
	CMD="$BIN/create_jail_root -U -v -a amd64 -r 10.3-RELEASE -p base,lib32 \"$TEST_ROOT/new_root\""
	assert_grep "$CMD" "Running freebsd-update"

	assert_end '"Root has been updated using freebsd-update"'
fi



if [ $test_ids -eq 1 ]; then
	# make sure FreeBSD update is run for verifying
	CMD="$BIN/create_jail_root -S -v -a amd64 -r 10.3-RELEASE -p base,lib32 \"$TEST_ROOT/new_root\""
	snapshot_root_fs "$TEST_ROOT/new_root"
	echo "invalidate" >> "$TEST_ROOT/new_root/bin/sh"
	assert_raises "$CMD" 7

	rollback_root_fs "$TEST_ROOT/new_root"
	assert_raises "$CMD" 0

	assert_end '"Root has been verified using freebsd-update"'
fi



if [ $test_copy_files -eq 1 ]; then
	# make sure files are copied
	CMD="$BIN/create_jail_root -F -v -a amd64 -r 10.3-RELEASE -p base,lib32 -f /etc/localtime,/etc/resolv.conf,/etc/hosts \"$TEST_ROOT/new_root\""
	assert_raises "$CMD" 0
	assert_raises "ls \"$TEST_ROOT/new_root/etc/localtime\"" 0
	assert_raises "ls \"$TEST_ROOT/new_root/etc/resolv.conf\"" 0
	assert_raises "ls \"$TEST_ROOT/new_root/etc/hosts\"" 0

	assert_end '"Files have been copied correctly"'
fi



if [ $do_cleanup -eq 1 ]; then
	destroy_root_fs "$TEST_ROOT/new_root"
fi

