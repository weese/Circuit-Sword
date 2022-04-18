# Install Docker for Mac
#  - increase resources to e.g. 8 CPUs
#  - enable Experimental Features -> Enable VirtuoFS accelerated directory sharing
# Download folder https://github.com/geerlingguy/raspberry-pi-pcie-devices/tree/master/extras/cross-compile

# docker-compose up -d
# docker attach cross-compile

# Inside the container run:

git clone --depth=1 https://github.com/raspberrypi/linux --branch rpi-5.10.y
cd linux
patch -p1 -d sound/usb < ../sound-module/snd-usb-audio-0.1/patches/fix-volume.patch

# Use default conf with RTL8723BS enabled
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2709_defconfig
sed -i 's/# CONFIG_RTL8723BS is not set/CONFIG_RTL8723BS=m/' .config

# (Optionally) Either edit the .config file by hand or use menuconfig:
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig

# Compile kernel and wait 10min
make -j8 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs

mkdir ../modules
make INSTALL_MOD_PATH=../modules/ modules_install

rm -f ../modules/lib/modules/*/build
rm -f ../modules/lib/modules/*/source

mkdir ../pi
mkdir ../pi/overlays

KERNEL=kernel7

cp arch/arm/boot/dts/*.dtb ../pi/
cp arch/arm/boot/dts/overlays/*.dtb* ../pi/overlays/
cp arch/arm/boot/dts/overlays/README ../pi/overlays/
cp arch/arm/boot/zImage ../pi/$KERNEL.img

mkdir -p /mnt/fat32
mkdir -p /mnt/ext4

FILE=retropie-buster-4.8-rpi2_3_zero2w.img
BASE_IMAGE=https://github.com/RetroPie/RetroPie-Setup/releases/download/4.8/$FILE.gz
# wget $BASE_IMAGE
# gunzip $FILE.gz

kpartx -a -v -s $FILE

mount /dev/mapper/loop0p1 /mnt/fat32

cp /mnt/fat32/$KERNEL.img /mnt/fat32/$KERNEL-backup.img
cp ../pi/$KERNEL.img /mnt/fat32/$KERNEL.img
cp ../pi/*.dtb /mnt/fat32/
cp ../pi/overlays/*.dtb* /mnt/fat32/overlays/
cp ../pi/overlays/README /mnt/fat32/overlays/

umount /mnt/fat32

mount /dev/mapper/loop0p2 /mnt/ext4

rsync -avh ../modules/ /mnt/ext4/

umount /mnt/ext4

kpartx -d -v $FILE

# copy image out of container
# docker cp <container_id>:build/linux/retropie-buster-4.8-rpi2_3_zero2w.img .