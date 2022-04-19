IMG=retropie-buster-4.8-rpi2_3_zero2w.img
IMG_URL=https://github.com/RetroPie/RetroPie-Setup/releases/download/4.8/$IMG.gz

${IMG}:
	wget ${IMG_URL}
	gunzip ${IMG}.gz

all: build-image

docker-build db: docker-build-kernel docker-build-image

docker-build-kernel:
	DOCKER_BUILDKIT=1 \
		docker build \
		--build-arg IMG=${IMG} \
		--target build-kernel \
		-t build-kernel \
		..

docker-build-image:
	DOCKER_BUILDKIT=1 \
		docker build \
		--build-arg IMG=${IMG} \
		--target build-image \
		-t build-image \
		..

build-kernel bk:
	docker run --rm \
		--name build-kernel \
		--volume ${PWD}/images:/build/images \
		--privileged \
		build-kernel \
		/bin/bash -c "./build-kernel.sh YES images/${IMG} && mv $(basename ${IMG})_kernel.img images/"

build-image bi:
	docker run --rm \
		--name build-image \
		--volume ${PWD}/images:/build/images \
		--privileged \
		build-image \
		/bin/bash -c "./build-image.sh YES images/$(basename ${IMG})_kernel.img && mv $(basename ${IMG})_* images/"
