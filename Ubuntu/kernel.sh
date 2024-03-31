### Remove old kernels
sudo dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | xargs sudo apt-get -y purge

### Reinstall latest kernel
dpkg -l | grep linux-image-.*-generic
sudo apt install --reinstall linux-image-5.19.0-41-generic

### Update current kernel
sudo update-initramfs -u -k $(uname -r)

### Upgrade to newest kernel
sudo apt full-upgrade -y 