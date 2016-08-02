#!/bin/bash +x
# Help a:       https://community.linuxmint.com/tutorial/view/2026
# Download at:  sudo wget https://raw.githubusercontent.com/YuggY/MintInstall/master/mint-install.sh && sudo wget https://raw.githubusercontent.com/YuggY/MintInstall/master/mint-post-install.sh && sudo chmod +x mint*.sh


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

export MNT="/mnt/@"

sudo mount /dev/mapper/${LVM_NAME}-root /mnt

sudo mount --bind /dev                         ${MNT}/dev
sudo mount --bind /dev/pts                     ${MNT}/dev/pts
sudo mount --bind /sys                         ${MNT}/sys
sudo mount --bind /proc                        ${MNT}/proc
sudo mount --bind /run                         ${MNT}/run
read -srn1 k

sudo dd bs=1024 count=4 if=/dev/urandom of=${MNT}/.key
sudo chmod 000 ${MNT}/.key
sudo chmod -R g-rwx,o-rwx ${MNT}/boot
sudo cryptsetup luksAddKey /dev/${LOCATION}1 ${MNT}/.key

echo "cp /.key \"\${DESTDIR}\"" | sudo tee -a ${MNT}/etc/initramfs-tools/hooks/crypto_keyfile
sudo chmod +x ${MNT}/etc/initramfs-tools/hooks/crypto_keyfile
read -srn1 k

#echo "lvm UUID=`sudo blkid -s UUID -o value /dev/${LOCATION}1` luks,keyscript=/bin/cat" | sudo tee -a ${MNT}/etc/crypttab
echo "crypt UUID=`sudo blkid -s UUID -o value /dev/${LOCATION}1` luks,keyscript=/bin/cat" | sudo tee -a ${MNT}/etc/crypttab
read -srn1 k

sudo chroot ${MNT} locale-gen --purge --no-archive
sudo chroot ${MNT} update-initramfs -u
read -srn1 k

sudo sed -i.bak 's/GRUB_HIDDEN_TIMEOUT=0/#GRUB_HIDDEN_TIMEOUT=0/' ${MNT}/etc/default/grub
sudo sed -i '10a GRUB_ENABLE_CRYPTODISK=y' ${MNT}/etc/default/grub
sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cryptdevice=\/dev\/'"${LOCATION}"'1:crypt"/' ${MNT}/etc/default/grub
read -srn1 k

sudo chroot ${MNT} update-grub
sudo chroot ${MNT} grub-mkconfig -o /boot/grub/grub.cfg
sudo chroot ${MNT} grub-install /dev/${LOCATION}
read -srn1 k

sudo umount ${MNT}/proc ${MNT}/dev/pts ${MNT}/dev ${MNT}/sys ${MNT}/run /mnt
