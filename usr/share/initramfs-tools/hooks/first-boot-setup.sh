#!/bin/sh -e

[ "$1" = prereqs ] && exit 0 || true

. /usr/share/initramfs-tools/hook-functions

copy_exec /sbin/sfdisk
copy_exec /sbin/resize2fs
copy_exec /sbin/mkfs.f2fs
copy_exec /sbin/resize.f2fs
copy_exec /bin/mkfs.btrfs
copy_exec /bin/btrfs
copy_exec /bin/grep
copy_exec /bin/sed
copy_exec /bin/tar
copy_exec /usr/bin/dialog
copy_exec /usr/bin/expr
