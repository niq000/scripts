#/bin/bash
# Used to install arch somewhat automatically

HOSTNAME=ArchLinux
DEST=/mnt
DEVICE=/dev/sda1
TZ=America/Los_Angeles
KEYMAP=en-dvorak

#mount the partition
#mount $DEVICE $DEST

#install the base system
#pacstrap $DEST base

#configure the system
#genfstab -p $DEST >> $DEST/etc/fstab
#arch-chroot $DEST

#set the hostname
echo $HOSTNAME > /etc/hostname

#configure timezone
if [ ! -f /etc/localtime ]; then
	ln -s /usr/share/zoneinfo/$TZ /etc/localtime
fi

#configure locale
sed -i 's/#en_US.UTF\-8 UTF\-8/en_US.UTF\-8 UTF\-8/g' /etc/locale.gen
locale-gen
locale > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

#make initial RAM disk
mkinitcpio -p linux

#set root password
echo "Create your root password\n"
passwd

#set networking

#set boot loader stuff (GRUB)
