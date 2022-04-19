#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root (sudo)"
  exit 1
fi

if [ $# != 3 ] ; then
  echo "Usage: ./<cmd> YES [fat32 root] [ext4 root]"
  exit 1
fi

#####################################################################
# Vars

if [[ $2 != "" ]] ; then
  DESTBOOT=$2
else
  DESTBOOT="/boot"
fi

if [[ $3 != "" ]] ; then
  DEST=$3
  MAKE_FLAGS="-j8 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-"
else
  DEST=""
  MAKE_FLAGS="-j4"
fi

KERNEL=kernel7

#####################################################################
# Functions
execute() { #STRING
  if [ $# != 1 ] ; then
    echo "ERROR: No args passed"
    exit 1
  fi
  cmd=$1
  
  echo "[*] EXECUTE: [$cmd]"
  eval "$cmd"
  ret=$?
  
  if [ $ret != 0 ] ; then
    echo "ERROR: Command exited with [$ret]"
    exit 1
  fi
  
  return 0
}

#####################################################################
# LOGIC!
echo "COMPILING.."

# Install Docker for Mac
#  - increase resources to e.g. 8 CPUs
#  - enable Experimental Features -> Enable VirtuoFS accelerated directory sharing
# Download folder https://github.com/geerlingguy/raspberry-pi-pcie-devices/tree/master/extras/cross-compile

# docker-compose up -d
# docker attach cross-compile

# Inside the container run:

#git clone --depth=1 https://github.com/raspberrypi/linux --branch rpi-5.10.y
#patch -p1 -d linux/sound/usb < ../sound-module/snd-usb-audio-0.1/patches/fix-volume.patch

execute "cd linux"

# Use default conf with RTL8723BS enabled
execute "make $MAKE_FLAGS bcm2709_defconfig"
execute "sed -i 's/# CONFIG_RTL8723BS is not set/CONFIG_RTL8723BS=m/' .config"

# (Optionally) Either edit the .config IMG by hand or use menuconfig:
# make $MAKE_FLAGS menuconfig

# (Cross-)compile kernel
execute "make $MAKE_FLAGS zImage modules dtbs"

execute "mkdir ../modules"
execute "make INSTALL_MOD_PATH=../modules/ modules_install"

execute "rm -f ../modules/lib/modules/*/build"
execute "rm -f ../modules/lib/modules/*/source"

execute "mkdir ../pi"
execute "mkdir ../pi/overlays"

execute "cp arch/arm/boot/dts/*.dtb ../pi/"
execute "cp arch/arm/boot/dts/overlays/*.dtb* ../pi/overlays/"
execute "cp arch/arm/boot/dts/overlays/README ../pi/overlays/"
execute "cp arch/arm/boot/zImage ../pi/$KERNEL.img"

execute "cp $DESTBOOT/$KERNEL.img $DESTBOOT/$KERNEL-backup.img"
execute "cp ../pi/$KERNEL.img $DESTBOOT/$KERNEL.img"
execute "cp ../pi/*.dtb $DESTBOOT/"
execute "cp ../pi/overlays/*.dtb* $DESTBOOT/overlays/"
execute "cp ../pi/overlays/README $DESTBOOT/overlays/"

execute "rsync -avh ../modules/ $DEST/"

#####################################################################
# DONE
echo "DONE!"
