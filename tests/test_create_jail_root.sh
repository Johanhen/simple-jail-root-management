#!/usr/local/bin/bash

#stop after first test failure
export STOP=1

do_all=1

do_setup=1
test_download=1
test_verification=1
test_extract=1
test_update=1
test_ids=1
test_copy_files=1
do_cleanup=1

if [ $do_all -eq 0 ]; then
	do_setup=0
	test_download=0
	test_verification=1
	test_extract=0
	test_update=0
	test_ids=0
	test_copy_files=1
	do_cleanup=0
fi

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

	begin_test "Downloading unknown packages fails"
	CMD="$BIN/create_jail_root -D -v -a amd64 -r 10.3-RELEASE -p unknown,base,lib32 \"$TEST_ROOT/new_root\""
	assert_raises "$CMD" 3
	end_test


	begin_test "Correct package sets are downloaded"
	CMD="$BIN/create_jail_root -D -v -a amd64 -r 10.3-RELEASE -p base,lib32 \"$TEST_ROOT/new_root\""
	assert_grep "$CMD" "Downloading $FTP_DIR/MANIFEST" "Downloading $FTP_DIR/base.txz" "Downloading $FTP_DIR/lib32.txz"
	assert_raises "test -f /var/tmp/create_jail_root/amd64/10.3-RELEASE/MANIFEST"
	assert_raises "test -f /var/tmp/create_jail_root/amd64/10.3-RELEASE/base.txz"
	assert_raises "test -f /var/tmp/create_jail_root/amd64/10.3-RELEASE/lib32.txz"
	end_test
fi



if [ $test_verification -eq 1 ]; then
	begin_test "Packages are verified correctly"
	# check if verification works
	CMD="$BIN/create_jail_root -V -v -a amd64 -r 10.3-RELEASE -p base,lib32 \"$TEST_ROOT/new_root\""
	assert_grep "$CMD" "Verifying checksum for base.txz" "Verifying checksum for lib32.txz"
	### make verification fail
	base_pkg="/var/tmp/create_jail_root/amd64/10.3-RELEASE/base.txz"
	cp "$base_pkg" "$base_pkg.bak"
	echo make_checksum_bad >> "$base_pkg"
	assert_raises "$CMD" 4
	### restore original file
	mv "$base_pkg.bak" "$base_pkg"
	end_test
fi



if [ $test_extract -eq 1 ]; then
	begin_test "Packages have been extracted"
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
	end_test
fi



if [ $test_update -eq 1 ]; then
	begin_test "Architecture has been stored in /etc/jail_architecture"
	# make sure architecture is saved
	assert "cat \"$TEST_ROOT/new_root/etc/jail_architecture\"" "amd64"
	end_test

	begin_test "Root has been updated using freebsd-update"
	# make sure FreeBSD update is run
	CMD="$BIN/create_jail_root -U -v -a amd64 -r 10.3-RELEASE -p base,lib32 \"$TEST_ROOT/new_root\""
	assert_grep "$CMD" "Running freebsd-update"

	end_test
fi



if [ $test_ids -eq 1 ]; then
	begin_test "Root has been verified using freebsd-update"
	# make sure FreeBSD update is run for verifying
	CMD="$BIN/create_jail_root -S -v -a amd64 -r 10.3-RELEASE -p base,lib32 \"$TEST_ROOT/new_root\""
	snapshot_root_fs "$TEST_ROOT/new_root"
	echo "invalidate" >> "$TEST_ROOT/new_root/bin/sh"
	assert_raises "$CMD" 7

	rollback_root_fs "$TEST_ROOT/new_root"
	assert_raises "$CMD" 0

	end_test
fi



if [ $test_copy_files -eq 1 ]; then
	begin_test "Copying of file (-f)"

	snapshot_root_fs "$TEST_ROOT/new_root"
	CMD="$BIN/create_jail_root -F -v -a amd64 -r 10.3-RELEASE -p base,lib32 -f '' \"$TEST_ROOT/new_root\""
	assert_raises "$CMD" 0
	assert_raises "ls \"$TEST_ROOT/new_root/etc/localtime\"" 1
	assert_raises "ls \"$TEST_ROOT/new_root/etc/resolv.conf\"" 1

	rollback_root_fs "$TEST_ROOT/new_root"

	# make sure files are copied
	CMD="$BIN/create_jail_root -F -v -a amd64 -r 10.3-RELEASE -p base,lib32 -f /etc/localtime,/etc/resolv.conf,/etc/hosts \"$TEST_ROOT/new_root\""
	assert_raises "$CMD" 0
	assert_raises "ls \"$TEST_ROOT/new_root/etc/localtime\"" 0
	assert_raises "ls \"$TEST_ROOT/new_root/etc/resolv.conf\"" 0
	assert_raises "ls \"$TEST_ROOT/new_root/etc/hosts\"" 0

	end_test
fi



if [ $do_cleanup -eq 1 ]; then
	destroy_root_fs "$TEST_ROOT/new_root"
fi

