# first-boot-setup

This is a debian package which simplifies doing some stuff on first boot, such as asking some questions, installing stuff, and so on.

# What it does

The `first-boot-setup` script starts in the initramfs uning `initramfs-tools` at the `local-premount` stage. It expects the rootfs to be formatted using
ext4 and the device file to be specified directly. It mounts the rootfs, chroots into it and executes the script `/usr/share/first-boot-setup/setup.sh`.
This script reconfigures the locales package and then let's the user set a new root password.
After that, it installs all packages listed in `/usr/share/first-boot-setup/dummy_packages_to_replace`. This meant for replacing dummy packages with real ones
which may have been required by other packages but couldn't be installed in a chroot. It then executes all scripts in `/usr/share/first-boot-setup/pre_target_install/`.
It then installs all packages listed in `/usr/share/first-boot-setup/packages_to_install`. After that, it executes all scripts in `/usr/share/first-boot-setup/post_target_install/`.
It then cleans the apt cache, removes itself & rebuilds the initramfs. After it exits the chroot, it unmounts the rootfs. Finally, it resizes the rootfs partition and continues
the boot process normally.

All packages it installs and their dependencies have to be in the `/usr/share/first-boot-setup/temp-repo/` folder.
