#!/bin/bash +x
# Help at https://community.linuxmint.com/tutorial/view/2026

export LOCATION="sdc"
export AES_SIZE="256"
export LVM_NAME="lvm"
export LVM_SWAP="3G"
export LVM_ROOT="17G"

clear
echo -e "
Current Config:
  LOCATION=${LOCATION}
  AES_SIZE=${AES_SIZE}
  LVM_NAME=${LVM_NAME}
  LVM_SWAP=${LVM_SWAP}
  LVM_ROOT=${LVM_ROOT}
"
lsblk
echo -e "
Edit this file and CHECK that all the install suit your needs!
"
read -srn1 k

sudo mount /dev/mapper/${LVM_NAME}-root /mnt
sudo ln /mnt/@/* /mnt

sudo mount --bind /dev                         /mnt/dev
sudo mount --bind /dev/pts                     /mnt/dev/pts
sudo mount --bind /sys                         /mnt/sys
sudo mount --bind /proc                        /mnt/proc
sudo mount --bind /run                         /mnt/run
read -srn1 k

sudo dd bs=1024 count=4 if=/dev/urandom of=/mnt/.key
sudo chmod 000 /mnt/.key
sudo chmod -R g-rwx,o-rwx /mnt/boot
sudo cryptsetup luksAddKey /dev/${LOCATION}1 /mnt/.key

echo "cp /.key \"\${DESTDIR}\"" | sudo tee -a /mnt/etc/initramfs-tools/hooks/crypto_keyfile
sudo chmod +x /mnt/etc/initramfs-tools/hooks/crypto_keyfile
read -srn1 k

#echo "lvm UUID=`sudo blkid -s UUID -o value /dev/${LOCATION}1` luks,keyscript=/bin/cat" | sudo tee -a /mnt/etc/crypttab
echo "crypt UUID=`sudo blkid -s UUID -o value /dev/${LOCATION}1` luks,keyscript=/bin/cat" | sudo tee -a /mnt/etc/crypttab
read -srn1 k

sudo chroot /mnt locale-gen --purge --no-archive
sudo chroot /mnt update-initramfs -u
read -srn1 k

sudo sed -i.bak 's/GRUB_HIDDEN_TIMEOUT=0/#GRUB_HIDDEN_TIMEOUT=0/' /mnt/etc/default/grub
sudo sed -i '10a GRUB_ENABLE_CRYPTODISK=y' /mnt/etc/default/grub
sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cryptdevice=\/dev\/'"${LOCATION}"'1:crypt"/' /mnt/etc/default/grub
read -srn1 k

sudo chroot /mnt update-grub
sudo chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
sudo chroot /mnt grub-install /dev/${LOCATION}
read -srn1 k

sudo umount /mnt/proc /mnt/dev/pts /mnt/dev /mnt/sys /mnt/run /mnt
