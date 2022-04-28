BOARD?=cs

ifeq ($(BOARD),"cs")
# Latest
TARGET=cm3
IMG=retropie-buster-4.8-rpi2_3_zero2w
IMG_URL=https://github.com/RetroPie/RetroPie-Setup/releases/download/4.8/${IMG}.img.gz
BRANCH=rpi-5.15.y

# Anthology's distro
# IMG=retropie-buster-4.7.1-rpi2_3
# IMG_URL=https://github.com/RetroPie/RetroPie-Setup/releases/download/4.7.1/${IMG}.img.gz
# BRANCH=stable
KERNEL=kernel7
else
# Latest SAIO ()
BOARD=saio
TARGET=pi
IMG=retropie-buster-4.8-rpi1_zero
IMG_URL=https://github.com/RetroPie/RetroPie-Setup/releases/download/4.8/${IMG}.img.gz
BRANCH=rpi-5.15.y
KERNEL=kernel
endif

all: build-image

clean:
	rm images/${IMG}_*.img

docker-build db: docker-build-kernel docker-build-image

.PHONY: docker-build-kernel
docker-build-kernel dbk:
	DOCKER_BUILDKIT=1 \
		docker build --progress=plain \
		--build-arg TARGET=${TARGET} \
		--build-arg BRANCH=${BRANCH} \
		--target build-kernel \
		-t build-${TARGET}-${BRANCH} \
		..

.PHONY: docker-build-image
docker-build-image dbi:
	DOCKER_BUILDKIT=1 \
		docker build --progress=plain \
		--target build-image \
		-t build-image \
		..

images/${IMG}.img:
	mkdir -p images
	cd images; \
	wget ${IMG_URL}; \
	gunzip ${IMG}.img.gz

.PHONY: build-kernel bk
build-kernel bk images/${IMG}_${BRANCH}.img: images/${IMG}.img
	docker run --rm \
		--name build-kernel \
		--volume ${PWD}/images:/build/images \
		--privileged \
		build-${TARGET}-${BRANCH} \
		/bin/bash -c "KERNEL=${KERNEL} ./build-kernel.sh YES /build/images/${IMG}.img && mv ${IMG}_kernel.img /build/images/${IMG}_${BRANCH}.img"

.PHONY: build-image bi
build-image bi: images/${IMG}_${BRANCH}.img
	docker run --rm \
		--name build-image \
		--volume ${PWD}/images:/build/images \
		--privileged \
		build-image \
		/bin/bash -c "./build-image.sh YES /build/images/${IMG}_${BRANCH}.img ${BOARD} && mv ${IMG}_* /build/images/"
