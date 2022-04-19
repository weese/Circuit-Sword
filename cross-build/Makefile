# Latest (not working)
# IMG=retropie-buster-4.8-rpi2_3_zero2w
# IMG_URL=https://github.com/RetroPie/RetroPie-Setup/releases/download/4.8/${IMG}.img.gz
# KERNEL=stable

# Anthology's distro
IMG=retropie-buster-4.7.1-rpi2_3
IMG_URL=https://github.com/RetroPie/RetroPie-Setup/releases/download/4.7.1/${IMG}.img.gz
KERNEL=stable

all: build-image

clean:
	rm images/${IMG}_*.img

docker-build db: docker-build-kernel docker-build-image

.PHONY: docker-build-kernel
docker-build-kernel:
	DOCKER_BUILDKIT=1 \
		docker build \
		--build-arg BRANCH=${KERNEL} \
		--target build-kernel \
		-t build-kernel-${KERNEL} \
		..

.PHONY: docker-build-image
docker-build-image:
	DOCKER_BUILDKIT=1 \
		docker build \
		--target build-image \
		-t build-image \
		..

images/${IMG}.img:
	cd images; \
	wget ${IMG_URL}; \
	gunzip ${IMG}.img.gz

.PHONY: build-kernel bk
build-kernel bk images/${IMG}_kernel.img: images/${IMG}.img
	docker run --rm \
		--name build-kernel \
		--volume ${PWD}/images:/build/images \
		--privileged \
		build-kernel \
		/bin/bash -c "./build-kernel.sh YES images/${IMG}.img && mv ${IMG}_kernel.img images/"

.PHONY: build-image bi
build-image bi: images/${IMG}_kernel.img
	docker run --rm \
		--name build-image \
		--volume ${PWD}/images:/build/images \
		--privileged \
		build-image \
		/bin/bash -c "./build-image.sh YES images/${IMG}_kernel.img && mv ${IMG}_* images/"
