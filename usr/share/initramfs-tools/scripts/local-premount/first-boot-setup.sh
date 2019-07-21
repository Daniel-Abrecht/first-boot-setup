#!/bin/sh

[ "$1" = prereqs ] && exit 0 || true
. /scripts/functions

part2dev(){
  [ -b "$1" ] || return 1
  res="/dev/$(printf '%s\n' /sys/block/*/"$(printf '%s' "$1" | grep -o "[^/]*$")" | sed -n 's|.*/\([^/]\+\)/[^/]\+$|\1|p')"
  [ -b "$res" ] || return 1
  printf '%s\n' "$res"
  return 0
}

if ! rootdisk="$(part2dev "$ROOT")" || ! partnumber="$(printf '%s\n' "$ROOT" | grep -o '[0-9]*$')"
then
  log_failure_msg "first-boot-setup: Not sure how to handle root=\"$root\""
  exit 0
fi

export fstype=ext4

mkdir /tmpmnt
mount -w -t "$fstype" "$ROOT" /tmpmnt/
mount -o bind /dev/ /tmpmnt/dev/
if [ -x /tmpmnt/usr/share/first-boot-setup/setup.sh ]
then
  if ! chroot /tmpmnt/ /usr/share/first-boot-setup/setup.sh
  then
    umount -f /tmpmnt/dev/
    umount -f /tmpmnt/
    exit 0
  fi
fi
if [ -f /tmpmnt/tmp/setupenv ]
then
  . /tmpmnt/tmp/setupenv
  rm -f /tmpmnt/tmp/setupenv
fi
sync /tmpmnt/
umount -f /tmpmnt/dev/
umount -f /tmpmnt/

#case "$fstype" in
#esac

echo ', +' | sfdisk -N "$partnumber" "$rootdisk"

case "$fstype" in
  *) resize2fs "$ROOT" ;;
esac

