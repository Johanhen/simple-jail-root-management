TEST_ROOT=/var/tmp/root_creation_tests
POOL=pool/nosnapshots
BIN="$work_dir/../src"



function assert_grep () {
	cmd=$1
	shift
	output=$(eval $cmd 2>&1)

	for pattern in "$@"; do
		assert_raises "grep  -E -e \"$pattern\" <<< \"$output\"" 0
	done
}

function create_root_fs () {
	mountpoint=$1
	fs_name=${2:-$(basename $mountpoint)}
	if [ -z "$mountpoint" ]; then
		echo "Error in create_root_fs: empty mountpoint" >&2
		exit 1
	fi
	if [ -z "$fs_name" ]; then
		echo "Error in create_root_fs: empty fs_name" >&2
		exit 1
	fi
	zfs create -o mountpoint=$mountpoint $POOL/$fs_name
	if [ $? -ne 0 ]; then
		echo "Unable to create root fs $POOL/$fs_name for $mountpoint. Bailing out" >&2
		exit 1
	fi
}

function destroy_root_fs () {
	mountpoint=$1
	fs_name=${2:-$(basename $mountpoint)}
	if [ -z "$mountpoint" ]; then
		echo "Error in destroy_root_fs: empty mountpoint" >&2
		exit 1
	fi
	if [ -z "$fs_name" ]; then
		echo "Error in destroy_root_fs: empty fs_name" >&2
		exit 1
	fi
	if zfs list $POOL/$fs_name >& /dev/null; then
		zfs destroy -r $POOL/$fs_name
		if [ $? -ne 0 ]; then
			echo "Unable to destroy root fs $POOL/$fs_name for $mountpoint. Bailing out" >&2
			exit 1
		fi
	fi
}

function snapshot_root_fs () {
	mountpoint=$1
	fs_name=${2:-$(basename $mountpoint)}
	if [ -z "$mountpoint" ]; then
		echo "Error in create_root_fs: empty mountpoint" >&2
		exit 1
	fi
	if [ -z "$fs_name" ]; then
		echo "Error in create_root_fs: empty fs_name" >&2
		exit 1
	fi
	snapshot=$POOL/$fs_name@test_snap
	zfs list $snapshot  >& /dev/null && zfs destroy $snapshot
	if ! zfs snapshot $snapshot; then
		echo "Unable to create snapshot $snapshot" >&2
		exit 1
	fi
}

function rollback_root_fs () {
	mountpoint=$1
	fs_name=${2:-$(basename $mountpoint)}
	if [ -z "$mountpoint" ]; then
		echo "Error in create_root_fs: empty mountpoint" >&2
		exit 1
	fi
	if [ -z "$fs_name" ]; then
		echo "Error in create_root_fs: empty fs_name" >&2
		exit 1
	fi
	snapshot=$POOL/$fs_name@test_snap
	if !  zfs rollback $snapshot; then
		echo "Unable to create snapshot $snapshot" >&2
		exit 1
	fi
}


function begin_test () {
	test_name=$1
	echo "================================================================================"
	echo "Starting test \"$test_name\""
}

function end_test () {
	assert_end "\"$test_name\""
}

