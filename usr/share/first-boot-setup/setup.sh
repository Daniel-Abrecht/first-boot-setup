#!/bin/sh

export DEBCONF_FORCE_DIALOG=1
export SETUP_DIR="$(dirname "$0")"
export APT_CONFIG="$SETUP_DIR"/apt.conf

cd "$SETUP_DIR" || exit 1

cat >/usr/sbin/policy-rc.d <<EOF
#!/bin/sh
exit 101
EOF
chmod +x /usr/sbin/policy-rc.d
mount -t proc proc /proc/
mount -t sysfs sys /sys/
mount -o rw /boot/

cleanup(){
  rm -f /usr/sbin/policy-rc.d
  sync /
  sync /boot/
  umount -f /boot/
  umount -f /sys/
  umount -f /proc/
  exit 0
}
trap cleanup EXIT

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

# Update package list
apt-get update

# Remove dummy packages
for dummy in $(cat dummy_packages_to_replace)
do if [ "$(dpkg-query -W --showformat='${Status}\n' "$dummy" 2>&-)" = 'install ok installed' ]
  then apt-get -y install "$dummy" || true
fi; done

for script in pre_target_install/*
do
  [ -x "$script" ] || continue
  sh -x "$script"
done

# install remaining packages
apt-get -y install $(cat packages_to_install)

for script in post_target_install/*
do
  [ -x "$script" ] || continue
  sh -x "$script"
done

# clean apt cache
apt-get clean

# Remove first boot scripts
cd /
rm -rf "$SETUP_DIR"

apt-get -y purge first-boot-setup
update-initramfs -u

exit 0