#!/bin/bash
cd "$(dirname "$0")" || exit 1
export ARCHS=X64

# Install booter on physical disk.


if [ ! -f "boot${ARCHS}" ] || [ ! -f boot0 ] || [ ! -f boot1f32 ]; then
  echo "Boot files are missing from this package!"
  echo "You probably forgot to build DuetPkg first."
  exit 1
fi

diskutil list
echo "Enter the number of the disk to install on:"
read N

if [[ ! $(diskutil info disk${N} |  sed -n 's/.*Device Node: *//p') ]]
then
  echo Disk $N not found
  exit
fi

FS=$(diskutil info disk${N}s1 | sed -n 's/.*File System Personality: *//p')
echo $FS

if [ "$FS" != "MS-DOS FAT32" ]
then
  echo "No FAT32 partition to install"
  exit
fi
echo "Install ➤ EFI System Partition"

# Write MBR
sudo fdisk -f boot0 -u /dev/rdisk${N}

diskutil umount disk${N}s1
sudo dd if=/dev/rdisk${N}s1 count=1  of=origbs
cp -v boot1f32 newbs
sudo dd if=origbs of=newbs skip=3 seek=3 bs=1 count=87 conv=notrunc
dd if=/dev/random of=newbs skip=496 seek=496 bs=1 count=14 conv=notrunc
sudo dd if=newbs of=/dev/rdisk${N}s1
sudo diskutil mount disk${N}s1
sudo cp -v "boot${ARCHS}" "$(diskutil info  disk"${N}"s1 |  sed -n 's/.*Mount Point: *//p')/boot"

sudo cp -rp EFI "$(diskutil info  disk${N}s1 |  sed -n 's/.*Mount Point: *//p')"

if [ $(diskutil info  disk${N} |  sed -n 's/.*Content (IOContent): *//p') == "FDisk_partition_scheme" ]
then
sudo fdisk -e /dev/rdisk$N <<-MAKEACTIVE
p
f 1
w
y
q
MAKEACTIVE
fi
Sleep 1
rm -rf ./origbs
rm -rf ./newbs
Open ./Notification/Install-EFI.app