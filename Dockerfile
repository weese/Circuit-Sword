FROM debian:buster AS base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get clean && apt-get update && \
    apt-get install -y \
    git bc bison flex libssl-dev python3 make kmod libc6-dev libncurses5-dev \
    crossbuild-essential-armhf \
    crossbuild-essential-arm64 \
    vim wget kpartx rsync sudo util-linux cloud-guest-utils

RUN mkdir /build
RUN mkdir -p /mnt/fat32
RUN mkdir -p /mnt/ext4

WORKDIR /build

CMD ["bash"]


# Cross compile kernel
FROM base AS build-kernel
ARG TARGET
ARG BRANCH
VOLUME /build/images

WORKDIR /usr/src

COPY sound-module/snd-usb-audio-0.1/patches/fix-volume.patch .
RUN --mount=type=cache,target=/usr/src/linux/ \
  rm -rf linux/* linux/.[!.]*; \
  git clone --depth=1 https://github.com/raspberrypi/linux --branch ${BRANCH}
RUN --mount=type=cache,target=/usr/src/linux/ \
  patch -p1 -d linux/sound/usb < fix-volume.patch
COPY cross-build/build-kernel.sh .
COPY cross-build/compile-kernel.sh .
COPY cross-build/install-kernel.sh .
RUN --mount=type=cache,target=/usr/src/linux/ \
  ./compile-kernel.sh $TARGET -j8 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-

CMD ["bash"]


# Extend image for CSO CM3
FROM base AS build-image
VOLUME /build/images

COPY build/build-image.sh .
COPY install.sh /
COPY . /cs

CMD ["bash"]
