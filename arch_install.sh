#/bin/bash
# Used to install arch somewhat automatically

HOSTNAME=ArchVM
DEST=/mnt
DEVICE=/dev/sda
TZ=America/Los_Angeles
KEYMAP=dvorak
PASSWORD=abc123!

usage() {
	echo "arch_install.sh setup"
}

#partition the hard disk into 3 partitions, boot, swap and main.
partition() {
	echo "##### Formating Disk $DEVICE\n"
	#Format the disk
	#create a boot partition, a swap partition
	#and a 3rd parition for all the data
	parted -s $DEVICE \
	mklabel msdos \
	mkpart primary ext2 1 100M \
	mkpart primary linux-swap 100M 8000M \
	mkpart primary ext4 8000M 100% \
	set 1 boot on
}

#setup the swap partition
function swap() {
	mkswap /dev/sda2
	swapon /dev/sda2
}

#setup and mount the boot partition. Needs to be called after the btrfs_init() function
function boot() {
	mkfs.ext2 /dev/sda1
	mkdir $DEST/boot
	mount /dev/sda1 $DEST/boot
}

#initialize the btrfs volumes and mount them to prepare for OS installation.
btrfs_init() {
	echo "##### BTRFS INIT\n"

	#format partition
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

  #mount home volume to /mnt/home
	mkdir $DEST/home
	mount -o noatime,compress=lzo,discard,autodefrag,subvol=home /dev/sda3 $DEST/home
}

init() {
	echo "##### INIT\n"

  swap
  btrfs_init
  boot

	#install the base system
	pacstrap $DEST base
	
	#configure the system
	genfstab -p $DEST >> $DEST/etc/fstab

  cp $0 /mnt/root/arch_install.sh
	arch-chroot $DEST /root/arch_install.sh config
}

#handle all the system configuration stuff. Setting the hostname, timezone, etc...
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
  pkgs
  aura
  salt_cfg
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

# install essential packages to finish configuring the system.
pkgs() { 
  PKGS="base-devel git salt"
  pacman -S --noconfirm $PKGS
}

# This function is used to install everything. You should only need to run this
# function, unless you are testing the other functions independently.
setup() {
	partition
	init
}

# Install and configure salt for masterless mode. Then run state.highstate to
# finish setting things up.
salt_cfg() {
	sed -i 's/#file_client: remote/file_client: local/g' /etc/salt/minion
  systemctl enable salt-minion
  cd /srv && git clone https://github.com/niq000/arch_salt.git
  mv arch_salt salt/
  salt-call --local state.highstate
}


if [ "$1" == "" ]; then
	usage
else
	$1
fi
