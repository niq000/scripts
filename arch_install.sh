#/bin/bash
# Used to install arch somewhat automatically

HOSTNAME=ArchVM
DEST=/mnt
DEVICE=/dev/sda
TZ=America/Los_Angeles
KEYMAP=dvorak
PASSWORD=abc123!

usage() {
	echo "arch_install.sh init|config|networking|boot_loader"
}

format() {
	echo "##### Formating Disk $DEVICE\n"
	#Format the disk
	#create a boot partition, a swap partition
	#and a 3rd parition for all the data
	parted -s $DEVICE \
	mklabel msdos \
	mkpart primary ext2 1 100M \
	mkpart primary linux-swap 100M 16000M \
	mkpart primary ext4 16000M 100% \
	set 1 boot on
}

btrfs_init() {
	echo "##### BTRFS INIT\n"
	mkswap /dev/sda2
	swapon /dev/sda2

	#format partitions
	mkfs.ext2 /dev/sda1
	mkfs.btrfs -L Arch /dev/sda3
	
	#mount btrfs to /mnt
	mount /dev/sda3 $DEST
	cd $DEST

	#create subvolume for root
	btrfs subvolume create root

	#create subvolume for home
	btrfs subvolume create home
	cd ~
	umount $DEST

	#mount root volume to /mnt
	mount -o noatime,compress=lzo,discard,autodefrag,subvol=root /dev/sda3 $DEST
	mkdir $DEST/boot
	mount /dev/sda1 $DEST/boot

	mkdir $DEST/home
	mount -o noatime,compress=lzo,discard,autodefrag,subvol=home /dev/sda3 $DEST/home
}

init() {
	echo "##### INIT\n"
	#install the base system
	pacstrap $DEST base
	
	#configure the system
	genfstab -p $DEST >> $DEST/etc/fstab

  cp $0 /mnt/root/arch_install.sh
	arch-chroot $DEST /root/arch_install.sh config
}

config() {
	echo "##### CONFIG\n"

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
  echo -en "$PASSWORD\n$PASSWORD" | passwd

	networking
	boot_loader
}

#set networking
networking() {
	echo "##### NETWORKING\n"

  # @todo: add some logic here for wifi-related packages/config

	ETH=$(ls /sys/class/net | grep enp)
	echo "Trying to enable dhcpcd for interface: $ETH"
	systemctl enable dhcpcd@$ETH
}

#set boot loader stuff (GRUB)
boot_loader() {
	echo "##### BOOTLOADER\n"
	pacman --noconfirm -S grub
	grub-install --target=i386-pc --recheck $DEVICE
	grub-mkconfig -o /boot/grub/grub.cfg
}

# install aura
aura() {
  #install aura from aur
  curl https://aur.archlinux.org/packages/au/aura-bin/aura-bin.tar.gz | tar xfz -
  cd aura-bin
  makepkg -si --noconfirm --asroot
  cd .. 
  rm -rf aura-bin/
}

# install essential packages
pkgs() { 
  PKGS="base-devel vim git"
  pacman -S --noconfirm $PKGS
}

setup() {
	format
	btrfs_init
	init
  pkgs
  aura
}


if [ "$1" == "" ]; then
	usage
else
	$1
fi
