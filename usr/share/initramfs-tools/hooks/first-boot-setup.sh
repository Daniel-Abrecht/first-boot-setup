#!/bin/sh -e

[ "$1" = prereqs ] && exit 0 || true

. /usr/share/initramfs-tools/hook-functions

copy_exec /sbin/sfdisk
copy_exec /sbin/resize2fs
copy_exec /bin/grep
copy_exec /bin/sed
