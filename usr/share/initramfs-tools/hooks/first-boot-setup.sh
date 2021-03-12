#!/bin/sh -e

[ "$1" = prereqs ] && exit 0 || true

. /usr/share/initramfs-tools/hook-functions

copy_exec /sbin/sfdisk
copy_exec /sbin/resize2fs
copy_exec /sbin/resize.f2fs
copy_exec /sbin/fsck
copy_exec /sbin/logsave # Needed by fsck scripts
copy_exec /sbin/fsck.f2fs
copy_exec /sbin/fsck.ext4
copy_exec /bin/grep
copy_exec /bin/sed
copy_exec /bin/tar
