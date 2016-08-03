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

sudo parted -s /dev/${LOCATION} mklabel msdos
sudo parted -a optimal -s /dev/${LOCATION} mkpart primary 0% 100%
sudo cryptsetup -v --cipher aes-xts-plain64 --key-size ${AES_SIZE} --hash sha${AES_SIZE} --iter-time 2000 --use-random luksFormat /dev/${LOCATION}1
sudo cryptsetup luksOpen /dev/${LOCATION}1 crypt

sudo pvcreate /dev/mapper/crypt
sudo vgcreate ${LVM_NAME} /dev/mapper/crypt
sudo lvcreate -L ${LVM_SWAP} ${LVM_NAME} -n swap
sudo lvcreate -L ${LVM_ROOT} ${LVM_NAME} -n root
sudo lvcreate -l +100%FREE   ${LVM_NAME} -n home

sudo mkswap -L swap /dev/${LVM_NAME}/swap

echo -e "
NEXT STEPS:

PLEASE WAIT - Installer will open shortly

Continue ->
Continue ->
     Something Else ->
     Set MountPoints and Format the Partitions ->
     Install Now ->
Continue ->
Continue ->

...Instalation...

[Continue Testing]
"

sudo sh -c 'ubiquity -b gtk_ui'&
