# Fix the too-loud-volume issue on Raspbian Buster and later

## Option 1 (preferred): DEB package install
```
sudo apt-get update
sudo apt-get install raspberrypi-kernel-headers subversion wget unzip
wget https://github.com/weese/Circuit-Sword/raw/master/sound-module/snd-usb-audio-dkms_0.1_armhf.deb
sudo dpkg -i snd-usb-audio-dkms_0.1_armhf.deb
```

## Option 2: DKMS manual install
```
wget https://github.com/weese/Circuit-Sword/archive/refs/heads/master.zip
unzip master.zip
sudo cp -r Circuit-Sword-master/snd-usb-audio-0.1 /usr/src/
sudo dkms add -m snd-usb-audio/0.1
sudo dkms build -m snd-usb-audio/0.1
sudo dkms install -m snd-usb-audio/0.1
```

## Option 3: Last resort, if nothing else works
```
wget https://github.com/weese/Circuit-Sword/archive/refs/heads/master.zip
unzip master.zip
cd Circuit-Sword-master/sound-module
./fix-for-installed-kernel.sh
```
