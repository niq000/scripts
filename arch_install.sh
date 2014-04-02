#/bin/bash
# Used to install arch somewhat automatically

HOSTNAME=ArchLinux
DEST=/mnt
DEVICE=/dev/sda
PARTION=1
TZ=America/Los_Angeles
KEYMAP=dvorak

usage() {
	echo "arch_install.sh init|config|networking|boot_loader"
}

init() {
	#mount the partition
	mount $DEVICE$PARTITION $DEST
	
	#install the base system
	pacstrap $DEST base
	
	#configure the system
	genfstab -p $DEST >> $DEST/etc/fstab
	arch-chroot $DEST
}

config() {
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
	echo "Create your root password"
	passwd
}

#set networking
networking() {
	echo "##### Networking"
	ETH=$(ls /sys/class/net | grep enp)
	echo "Trying to enable dhcpcd for interface: $ETH"
	systemctl enable dhcpcd@$ETH
}

#set boot loader stuff (GRUB)
boot_loader() {
	echo "##### Bootloader"
	pacman --noconfirm -S grub
	grub-install --target=i386-pc --recheck --debug $DEVICE
	grub-mkconfig -o /boot/grub/grub.cfg
}

if [ "$1" == "" ]; then
	usage
else
	$1
fi
