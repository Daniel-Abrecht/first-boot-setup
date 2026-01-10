#!/bin/sh

[ "$1" = prereqs ] && exit 0 || true
. /scripts/functions

# Make sure we have the device file
case "$ROOT" in
  PARTUUID=*) ROOT="/dev/disk/by-partuuid/${ROOT#PARTUUID=}" ;;
  UUID=*) ROOT="/dev/disk/by-uuid/${ROOT#UUID=}" ;;
esac

# This may be a symlink in /dev/disk, let's resolve it, because to resize the partition, we need to figure out the device
if [ -h "$ROOT" ]
  then ROOT="$(readlink -f "$ROOT")"
fi

part2dev(){
  [ -b "$1" ] || return 1
  res="$(printf '%s\n' /sys/block/*/"$(printf '%s' "$1" | grep -o "[^/]*$")" | sed -n 's|.*/\([^/]\+\)/[^/]\+$|\1|p')"
  [ -b "/dev/$res" ] || return 1
  printf '%s\n' "$res"
  return 0
}

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
do [ -b "$ROOT" ] && break
  sleep 1
done

if ! rootdisk="$(part2dev "$ROOT")" || ! partnumber="$(printf '%s\n' "$ROOT" | grep -o '[0-9]*$')"
then
  log_failure_msg "first-boot-setup: Not sure how to handle root=\"$ROOT\""
  exit 0
fi

set -ex

FSTYPE="$(get_fstype "$ROOT")"

echo ', +' | sfdisk -N "$partnumber" "/dev/$rootdisk"
case "$FSTYPE" in
  ext?)
    fsck.ext4 -f -y "$ROOT" || true
    resize2fs -f "$ROOT"
    ;;
  f2fs)
    fsck.f2fs -f "$ROOT" || true
    resize.f2fs "$ROOT"
    ;;
esac

set -e
mkdir /tmpmnt
mount -w -t "$FSTYPE" "$ROOT" /tmpmnt/
mount -o bind /dev/ /tmpmnt/dev/
set +e
if [ -x /tmpmnt/usr/share/first-boot-setup/setup.sh ]
then
  if ! chroot /tmpmnt/ /usr/share/first-boot-setup/setup.sh
  then
    umount -f /tmpmnt/dev/
    umount -f /tmpmnt/
    exit 0
  fi
fi
sync /tmpmnt/
umount -f /tmpmnt/dev/
umount -f /tmpmnt/
