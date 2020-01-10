#!/bin/sh

[ "$1" = prereqs ] && exit 0 || true
. /scripts/functions

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

export fstype=ext4

set -x
# Make partition a bit larger so there's enough space for the next step,
# but still small enough so we can make a copy of it
disk_space_mb="$(expr "$(cat /sys/block/"$rootdisk"/size)" '*' 512 / 1024 / 1024)"
less_than_half_of_disk_space="$(expr "$disk_space_mb" '*' 10 / 25)"
echo ", $less_than_half_of_disk_space"M | sfdisk -N "$partnumber" "/dev/$rootdisk"
resize2fs "$ROOT"
set +x

set -e
mkdir /tmpmnt
mount -w -t "$fstype" "$ROOT" /tmpmnt/
mount -o bind /dev/ /tmpmnt/dev/
set +e
if [ -x /tmpmnt/usr/share/first-boot-setup/setup.sh ]
then
  if ! chroot /tmpmnt/ /usr/share/first-boot-setup/setup_early.sh
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

if [ "$newfstype" = "$fstype" ]
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

set -ex

case "$newfstype" in
  ext*) newfsoptions="discard,relatime,errors=remount-ro" ;;
  *) newfsoptions="discard,relatime" ;;
esac

if [ "$newfstype" != "$fstype" ]
then

  printf '%s\n' "/dev/$rootdisk"* >odevlist
  sfdisk -d "/dev/$rootdisk" >olddisk
  echo ", $less_than_half_of_disk_space"M | sfdisk -a "/dev/$rootdisk"
  copypart=$(for x in "/dev/$rootdisk"*; do
    if grep -q "$x" odevlist
     then continue
    fi
    printf '%s\n' "$x"
    break
  done)
  [ -b "$copypart" ]
  mount -r -t "$fstype" "$ROOT" /tmpmnt/
  printf 'Moving files away from partition to be formatted...'
  total="$( cd /tmpmnt/; tar c --checkpoint=1024 --checkpoint-action=ttyout=. --total . 2>&1 >"$copypart" | grep -o ': [0-9]*' | grep -o '[0-9]*'; )"
  echo
  umount -f /tmpmnt/

  "mkfs.$newfstype" -f "$ROOT"
  mount -w -t "$newfstype" "$ROOT" /tmpmnt/
  echo "ROOTFSTYPE=$newfstype" >/conf/param.conf
  (
    cd /tmpmnt/
    set +x
    tar x --warning=no-timestamp --checkpoint=1024 --checkpoint-action='echo=%{r}T' <"$copypart" 3>&2 2>&1 1>&2 |
      grep -o ': [0-9]*' | grep -o  '[0-9]*' |
      while read s
        do expr "$s" '*' 100 / "$total"
      done | dialog --gauge "Moving files back to newly formatted partition..." 0 110
  )
  mount -o bind /dev/ /tmpmnt/dev/
  sed -i 's|^\([^ \t]\+\s\+/\s\+\)\('"$fstype"'\).*|\1'"$newfstype"'\t'"$newfsoptions"'\t0\t1|' /tmpmnt/etc/fstab
  chroot /tmpmnt/ /usr/share/first-boot-setup/setup.sh
  sync /tmpmnt/
  umount -f /tmpmnt/dev/
  umount -f /tmpmnt/
  sfdisk "/dev/$rootdisk" <olddisk

fi

echo ', +' | sfdisk -N "$partnumber" "/dev/$rootdisk"

case "$newfstype" in
  ext4) resize2fs "$ROOT" ;;
  f2fs) resize.f2fs "$ROOT" ;;
esac
