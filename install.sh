#!/bin/bash

# 
# This file originates from Kite's Circuit Sword control board project.
# Author: Kite (Giles Burgess)
# 
# THIS HEADER MUST REMAIN WITH THIS FILE AT ALL TIMES
#
# This firmware is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This firmware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this repo. If not, see <http://www.gnu.org/licenses/>.
#

if [ "$EUID" -ne 0 ]
  then echo "Please run as root (sudo)"
  exit 1
fi

if [ $# -lt 1 ] || [ $# -gt 5 ]; then
  echo "Usage: ./<cmd> YES [branch] [fat32 root] [ext4 root] [board]"
  exit 1
fi

#####################################################################
# Vars

if [[ $3 != "" ]] ; then
  DESTBOOT=$3
else
  DESTBOOT="/boot"
fi

if [[ $4 != "" ]] ; then
  DEST=$4
else
  DEST=""
fi

if [[ $5 != "" ]] ; then
  BOARD=$5
else
  BOARD="cs"
fi

GITHUBPROJECT="Circuit-Sword"
GITHUBURL="https://github.com/weese/$GITHUBPROJECT"
PIHOMEDIR="$DEST/home/pi"
BINDIR="$PIHOMEDIR/$GITHUBPROJECT"
# USER="pi"
USER=1000
POSTINSTALL="/usr/local/sbin/post-install.sh"

if [[ $2 != "" ]] ; then
  BRANCH=$2
else
  BRANCH="master"
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

post-execute() { #STRING
  if [ $# != 1 ] ; then
    echo "ERROR: No args passed"
    exit 1
  fi

  if [[ $DEST != "" ]] ; then
    if ! exists $DEST/$POSTINSTALL ; then
      echo "#!/bin/bash" > $DEST/$POSTINSTALL
      echo "set -e" >> $DEST/$POSTINSTALL
      chmod a+x $DEST/$POSTINSTALL
    fi
    echo "$1" >> $DEST/$POSTINSTALL
  else
    execute "$1"
  fi
}

install() { #STRING
  if [ $# != 1 ] ; then
    echo "ERROR: No args passed"
    exit 1
  fi

  if [[ $DEST != "" ]] ; then
    # We cannot simply extract as in the following command, because avrdude or something connected
    # causes kernel panics with the latest RetroPie 4.8
    # execute "dpkg -x $BINDIR/$1 $DEST/"
    #
    # Instead we install in a chroot which only works on ARM based hosts, e.g. Macbook M1 or RaspberryPi
    execute "sudo chroot $DEST dpkg -i /home/pi/$GITHUBPROJECT/$1"
  else
    execute "sudo dpkg -i $BINDIR/$1"
  fi
}

post-install() { #STRING
  if [ $# != 1 ] ; then
    echo "ERROR: No args passed"
    exit 1
  fi

  if [[ $DEST != "" ]] ; then
    if ! exists $DEST/$POSTINSTALL ; then
      echo "#!/bin/bash" > $DEST/$POSTINSTALL
      echo "set -e" >> $DEST/$POSTINSTALL
      chmod a+x $DEST/$POSTINSTALL
    fi
    echo "dpkg -i /home/pi/$GITHUBPROJECT/$1" >> $DEST/$POSTINSTALL
  else
    execute "sudo dpkg -i $BINDIR/$1"
  fi
}

exists() { #FILE
  if [ $# != 1 ] ; then
    echo "ERROR: No args passed"
    exit 1
  fi
  
  file=$1
  
  if [ -f $file ]; then
    echo "[i] FILE: [$file] exists."
    return 0
  else
    echo "[i] FILE: [$file] does not exist."
    return 1
  fi
}

#####################################################################
# LOGIC!
echo "INSTALLING.."

# Checkout code if not already done so
if ! exists "$BINDIR/LICENSE" ; then
  execute "git clone --recursive --depth 1 --branch $BRANCH $GITHUBURL $BINDIR"
fi
execute "chown -R $USER:$USER $BINDIR"

#####################################################################
# Copy required to /boot

# Config.txt bits
if ! exists "$DESTBOOT/config_ORIGINAL.txt" ; then
  execute "cp $DESTBOOT/config.txt $DESTBOOT/config_ORIGINAL.txt"
  execute "cp $BINDIR/settings/boot-$BOARD/* $DESTBOOT/"
fi

# Special case where config.txt has been updated on upgrade
if [[ ! $(grep "CS CONFIG VERSION: 1.0" "$DESTBOOT/config.txt") ]] ; then
  execute "cp $BINDIR/settings/boot-$BOARD/config.txt $DESTBOOT/config.txt"
fi

#####################################################################
# Copy required to /

# Copy USB sound
execute "cp $BINDIR/settings/asound.conf $DEST/etc/asound.conf"
execute "cp $BINDIR/settings/alsa-base.conf $DEST/etc/modprobe.d/alsa-base.conf"

# Copy autostart
if ! exists "$DEST/opt/retropie/configs/all/autostart_ORIGINAL.sh" ; then
  execute "mv $DEST/opt/retropie/configs/all/autostart.sh $DEST/opt/retropie/configs/all/autostart_ORIGINAL.sh"
  execute "cp $BINDIR/settings/splashscreen.list $DEST/etc/splashscreen.list"
fi
execute "cp $BINDIR/settings/autostart-$BOARD.sh $DEST/opt/retropie/configs/all/autostart.sh"
execute "chown $USER:$USER $DEST/opt/retropie/configs/all/autostart.sh"

# Copy ES safe shutdown script
execute "cp $BINDIR/settings/cs_shutdown.sh $DEST/opt/cs_shutdown.sh"

# Fix splashsreen sound
if exists "$DEST/etc/init.d/asplashscreen" ; then
  execute "sed -i \"s/ *both/ alsa/\" $DEST/etc/init.d/asplashscreen"
fi
if exists "$DEST/opt/retropie/supplementary/splashscreen/asplashscreen.sh" ; then
  execute "sed -i \"s/ *both/ alsa/\" $DEST/opt/retropie/supplementary/splashscreen/asplashscreen.sh"
fi

# Fix audio
if exists "$DEST/opt/retropie/emulators/mupen64plus/bin/mupen64plus.sh" ; then
  execute "sed -i \"s/mupen64plus-audio-omx/mupen64plus-audio-sdl/\" $DEST/opt/retropie/emulators/mupen64plus/bin/mupen64plus.sh"
fi

# Fix audio
if ! exists "$PIHOMEDIR/.vice/sdl-vicerc" ; then
  execute "mkdir -p $PIHOMEDIR/.vice/"
  execute "echo 'SoundOutput=2' > $PIHOMEDIR/.vice/sdl-vicerc"
  execute "chown -R $USER:$USER $PIHOMEDIR/.vice/"
fi

# Fix Bluetooth Audio
cat << EOF >> $DEST/opt/retropie/configs/all/runcommand-onstart.sh
#!/bin/bash
set -e
index=`pacmd list-cards | grep bluez_card -B1 | grep index | awk '{print $2}'`
pacmd set-card-profile $index off
pacmd set-card-profile $index a2dp_sink
EOF

# Install the pixel theme and set it as default
if ! exists "$DEST/etc/emulationstation/themes/pixel/system/theme.xml" ; then
  execute "mkdir -p $DEST/etc/emulationstation/themes"
  execute "rm -rf $DEST/etc/emulationstation/themes/pixel"
  execute "git clone --recursive --depth 1 --branch master https://github.com/krextra/es-theme-pixel.git $DEST/etc/emulationstation/themes/pixel"
  execute "cp -p $BINDIR/settings/es_settings.cfg $DEST/opt/retropie/configs/all/emulationstation/es_settings.cfg"
  execute "sed -i \"s/carbon/pixel/\" $DEST/opt/retropie/configs/all/emulationstation/es_settings.cfg"
fi

# Fix warning regarding 'failed to find mixer elements' message while entering an emulator 
if exists "$DEST/opt/retropie/configs/all/emulationstation/es_settings.cfg" ; then
  execute "echo '<string name=\"AudioDevice\" value=\"PCM\" />' >> $DEST/opt/retropie/configs/all/emulationstation/es_settings.cfg"
fi

# Install runcommand splash
#if ! exists "$DEST/opt/retropie/configs/desktop/launching.png" ; then
#  execute "rm -rf /tmp/es-runcommand-splash"
#  execute "git clone --recursive --depth 1 --branch master https://github.com/ehettervik/es-runcommand-splash.git /tmp/es-runcommand-splash"
#  execute "chown -R $USER:$USER /tmp/es-runcommand-splash"
#  execute "cp -rp /tmp/es-runcommand-splash/* $DEST/opt/retropie/configs"
#  execute "rm -rf /tmp/es-runcommand-splash"
#fi

# Install the reboot to hdmi scripts
execute "cp $BINDIR/settings/reboot_to_hdmi.sh $PIHOMEDIR/RetroPie/retropiemenu/reboot_to_hdmi.sh"
execute "cp -p $BINDIR/settings/reboot_to_hdmi.png $PIHOMEDIR/RetroPie/retropiemenu/icons/reboot_to_hdmi.png"
if [[ ! $(grep "reboot_to_hdmi" "$DEST/opt/retropie/configs/all/emulationstation/gamelists/retropie/gamelist.xml") ]] ; then
  execute "sed -i 's|</gameList>|  <game>\n    <path>./reboot_to_hdmi.sh</path>\n    <name>One Time Reboot to HDMI</name>\n    <desc>Enable HDMI and automatically reboot for it to apply. The subsequent power cycle will revert back to the internal screen. It is normal when enabled for the internal screen to remain grey/white.</desc>\n    <image>/home/pi/RetroPie/retropiemenu/icons/reboot_to_hdmi.png</image>\n  </game>\n</gameList>|g' $DEST/opt/retropie/configs/all/emulationstation/gamelists/retropie/gamelist.xml"
fi

# Enable 30sec autosave
execute "sed -i \"s/# autosave_interval =/autosave_interval = \"30\"/\" $DEST/opt/retropie/configs/all/retroarch.cfg"

# Disable 'wait for network' on boot
execute "rm -f $DEST/etc/systemd/system/dhcpcd.service.d/wait.conf"

# Remove wifi country disabler
execute "rm -f $DEST/etc/systemd/system/multi-user.target.wants/wifi-country.service"

# Copy wifi firmware
execute "mkdir -p $DEST/lib/firmware/rtlwifi/"
execute "cp $BINDIR/wifi-firmware/rtl* $DEST/lib/firmware/rtlwifi/"

# Copy bluetooth firmware
execute "mkdir -p $DEST/lib/firmware/rtl_bt/"
execute "cp $BINDIR/bt-driver/rtlbt_* $DEST/lib/firmware/rtl_bt/"

# Remove console=serial0 from cmdline to make UART-based bluetooth module work
execute "sed -i 's/console=serial0,115200//' $DESTBOOT/cmdline.txt"

# Fix long delay of boot because looking for wrong serial port
execute "sed -i \"s/dev-serial1.device/dev-ttyAMA0.device/\" $DEST/lib/systemd/system/hciuart.service"

# Install python-serial
install "settings/deb/python-serial_2.6-1.1_all.deb"

# Install rfkill
install "settings/deb/rfkill_0.5-1_armhf.deb"

# Install avrdude
# !! The following will work only with hosts that are ARM based, e.g. Macbook M1 or RaspberryPi
# Avrdude or something connected is causing kernel panics with the latest RetroPie 4.8 if not installed but only extracted :/
install "settings/deb/libftdi1_0.20-4_armhf.deb"
install "settings/deb/libhidapi-libusb0_0.8.0~rc1+git20140818.d17db57+dfsg-2_armhf.deb"
install "settings/deb/avrdude_6.3-20171130+svn1429-2+rpt1_armhf.deb"

# Install DKMS dependencies
install "settings/deb/libapr1_1.6.5-1_armhf.deb"
install "settings/deb/libaprutil1_1.6.1-4_armhf.deb"
install "settings/deb/libserf-1-1_1.3.9-7_armhf.deb"
install "settings/deb/libutf8proc2_2.3.0-1_armhf.deb"
install "settings/deb/libsvn1_1.10.4-1+deb10u3_armhf.deb"
install "settings/deb/subversion_1.10.4-1+deb10u3_armhf.deb"

# Installing the deb modules means to compile for all installed kernels, which takes ages, so we only add the DKMS modules
# post-install "sound-module/snd-usb-audio-dkms_0.1_armhf.deb"
# post-install "wifi-module/rtl8723bs-dkms_4.14_all.deb"
execute "dpkg -x $BINDIR/sound-module/snd-usb-audio-dkms_0.1_armhf.deb $DEST"
execute "dpkg -x $BINDIR/wifi-module/rtl8723bs-dkms_4.14_all.deb $DEST"
post-execute "dkms add -m snd-usb-audio -v 0.1"
post-execute "dkms add -m rtl8723bs -v 4.14"

# Install wiringPi
install "settings/deb/wiringpi_2.46_armhf.deb"

# Enable /ramdisk as a tmpfs (ramdisk)
if [[ $(grep '/ramdisk' $DEST/etc/fstab) == "" ]] ; then
  execute "echo 'tmpfs    /ramdisk    tmpfs    defaults,noatime,nosuid,size=100k    0 0' >> $DEST/etc/fstab"
fi

if [ -d $DEST/usr/lib/systemd/system ]; then
  SYSTEMD="$DEST/usr/lib/systemd/system"
else
  SYSTEMD="$DEST/lib/systemd/system"
fi

if [[ "$BOARD" == cs* ]]; then
  # Remove the old service
  execute "rm -f $DEST/etc/systemd/system/cs-osd.service"
  execute "rm -f $DEST/etc/systemd/system/multi-user.target.wants/cs-osd.service"
  execute "rm -f $SYSTEMD/cs-osd.service"

  # Install HUD service
  HUD=cs-osd
  execute "cp $BINDIR/hud/cs/cs-hud.service $SYSTEMD/$HUD.service"
else
  # Install OSD service
  HUD=saio-osd
  # execute "cp $BINDIR/hud/saio/saio-osd.service $SYSTEMD/$HUD.service"
  install "settings/deb/libpng12-0_1.2.54-6_armhf.deb"
fi

# Prepare for service install
execute "rm -f $DEST/etc/systemd/system/$HUD.service"
execute "rm -f $DEST/etc/systemd/system/multi-user.target.wants/$HUD.service"

# Install RTL Bluetooth service
execute "cp $BINDIR/bt-driver/rtl-bluetooth.service $DEST/lib/systemd/system/rtl-bluetooth.service"
execute "cp $BINDIR/bt-driver/rtk_hciattach $DEST/usr/bin/rtk_hciattach"

#execute "systemctl enable cs-hud.service"
execute "ln -s $SYSTEMD/$HUD.service $DEST/etc/systemd/system/$HUD.service"
execute "ln -s $SYSTEMD/$HUD.service $DEST/etc/systemd/system/multi-user.target.wants/$HUD.service"

#execute "systemctl enable rtl-bluetooth.service"
execute "ln -s $DEST/lib/systemd/system/rtl-bluetooth.service $DEST/etc/systemd/system/rtl-bluetooth.service"
execute "ln -s $DEST/lib/systemd/system/rtl-bluetooth.service $DEST/etc/systemd/system/multi-user.target.wants/rtl-bluetooth.service"

# Install DPI-CLONER service
execute "cp $BINDIR/dpi-cloner/dpi-cloner.service $SYSTEMD/dpi-cloner.service"

if [[ $DEST == "" ]] ; then
  execute "systemctl daemon-reload"
  execute "systemctl start $HUD.service"
fi

#####################################################################
# DONE
echo "DONE!"
