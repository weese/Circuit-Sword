FROM debian:buster AS base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get clean && apt-get update && \
    apt-get install -y \
    git bc sshfs bison flex libssl-dev python3 make kmod libc6-dev libncurses5-dev \
    crossbuild-essential-armhf \
    crossbuild-essential-arm64 \
    vim wget kpartx rsync sudo util-linux cloud-guest-utils

RUN mkdir -p /root/.ssh
RUN chmod 644 /root/.ssh

RUN mkdir /build
RUN mkdir -p /mnt/fat32
RUN mkdir -p /mnt/ext4

WORKDIR /build

CMD ["bash"]


# Cross compile kernel
FROM base AS build-kernel
ARG BRANCH
VOLUME /build/images

COPY sound-module/snd-usb-audio-0.1/patches/fix-volume.patch .
RUN git clone --depth=1 https://github.com/raspberrypi/linux --branch ${BRANCH}
RUN patch -p1 -d linux/sound/usb < fix-volume.patch

COPY cross-build/build-kernel.sh .
COPY cross-build/cross-compile-kernel.sh .

CMD ["bash"]


# Extend image for CSO CM3
FROM base AS build-image
VOLUME /build/images

COPY build/build-image.sh .
COPY install.sh /

CMD ["bash"]
