#!/bin/bash

set -e

if [[ $1 != "" ]] ; then
  MAKE_FLAGS="$@"
else
  MAKE_FLAGS?="-j4"
fi

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
# execute "sed -i 's/# CONFIG_RFKILL_GPIO is not set/CONFIG_RFKILL_GPIO=m/' .config"
#execute "sed -i 's/# CONFIG_BT_HCIUART_RTL is not set/CONFIG_BT_HCIUART_RTL=y/' .config"

# Use previous .config file 
# execute "cp ../config.template .config"
# execute "make $MAKE_FLAGS oldconfig"

# (Optionally) Either edit the .config IMG by hand or use menuconfig:
# make $MAKE_FLAGS menuconfig

# (Cross-)compile kernel
execute "make $MAKE_FLAGS zImage modules dtbs"

execute "mkdir ../modules"
execute "sudo make INSTALL_MOD_PATH=../modules/ modules_install"

execute "rm -f ../modules/lib/modules/*/build"
execute "rm -f ../modules/lib/modules/*/source"

execute "mkdir -p ../pi/overlays"

execute "cp .config ../config"
execute "cp arch/arm/boot/dts/*.dtb ../pi/"
execute "cp arch/arm/boot/dts/overlays/*.dtb* ../pi/overlays/"
execute "cp arch/arm/boot/dts/overlays/README ../pi/overlays/"
execute "cp arch/arm/boot/zImage ../pi/"

#####################################################################
# DONE
echo "COMPILATION DONE!"
