# simple-jail-root-management

''WORK IN PROGRESS''

This is a set of very simple `sh` scripts to manage FreeBSD jail (or chroot)
roots, i.e. to populate a directory with a FreeBSD userland.

## create-jail-root

The user specifies a release, an architecture and a package set (via config file
or command line options)  that should be installed to a target directory

The script then does the following:
 1. Check if the target directory exists
 1. Download the appropriate distritbution files from a FreeBSD mirror 
 1. Check the MD5 sum for the downloaded files
 1. Extract the downloaded files to the target directory
 1. Run `freebsd-update` to update to the latest patchlevel
 1. Run `freebsd-update` to check all files have the correct checksum
 1. Copy `resolv.conf` and `localtime` to the new root directory
 1. Set the hostname in the new root's `/etc/rc.conf`


