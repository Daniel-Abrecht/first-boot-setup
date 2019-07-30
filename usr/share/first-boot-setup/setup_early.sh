#!/bin/sh

export DEBCONF_FORCE_DIALOG=1
export SETUP_DIR="$(dirname "$0")"
export APT_CONFIG="$SETUP_DIR"/apt.conf

cd "$SETUP_DIR" || exit 1

setpw(){
  local pw=
  local confirm_pw=
  while [ -z "$pw" ] || [ "$pw" != "$confirm_pw" ]
  do
    pw="$(dialog --no-cancel --insecure --passwordbox "Please set the password for $1" 0 0 3>&1 1>&2 --output-fd 3)" || true
    [ -n "$pw" ] || continue
    confirm_pw="$(dialog --no-cancel --insecure --passwordbox "Please confirm the password" 0 0 3>&1 1>&2 --output-fd 3)" || true
  done
  printf '%s' "$1:$pw" | chpasswd
}

dpkg-reconfigure locales

setpw root

while [ -z "$devname" ] || printf "%s\n" "$devname" | grep -q '[^a-zA-Z0-9-]'
do
  devname="$(dialog --no-cancel --inputbox "Please choose a name for your device\n(Only alphanumeric characters and - are possible)" 0 0 3>&1 1>&2 --output-fd 3)"
  printf "%s\n" "$devname" >/etc/hostname
  hostname "$devname"
done

while [ -z "$newfstype" ]
  do newfstype="$(dialog --no-cancel --menu 'Which root filesystem type would you like to have?'  0 0 0 ext4 '' f2fs '' 3>&1 1>&2 --output-fd 3)"
done
printf 'newfstype=%s\n' "$newfstype" >>/tmp/setupenv

exit 0
