FROM debian:buster AS base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get clean && apt-get update && \
    apt-get install -y \
    git bc sshfs bison flex libssl-dev python3 make kmod libc6-dev libncurses5-dev \
    crossbuild-essential-armhf \
    crossbuild-essential-arm64 \
    vim wget kpartx rsync sudo

RUN mkdir -p /root/.ssh
RUN chmod 644 /root/.ssh

RUN mkdir /build
RUN mkdir -p /mnt/fat32
RUN mkdir -p /mnt/ext4

WORKDIR /build

CMD ["bash"]


# FROM base AS build-kernel

# COPY cross-compile-kernel.sh .
# RUN ./cross-compile-kernel.sh

FROM base AS build-image

VOLUME /build/images

COPY build/build-image.sh .
COPY install.sh /

CMD ["bash"]

RUN 