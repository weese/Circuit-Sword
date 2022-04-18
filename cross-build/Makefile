FILE=retropie-buster-4.8-rpi2_3_zero2w.img
BASE_IMAGE=https://github.com/RetroPie/RetroPie-Setup/releases/download/4.8/$FILE.gz

${FILE}:
	wget ${BASE_IMAGE}
	gunzip ${FILE}.gz

all: build-image

docker-build db: docker-build-image

docker-build-image:
	DOCKER_BUILDKIT=1 \
		docker build \
		--build-arg FILE=${FILE} \
		--target build-image \
		-t build-image \
		..

build-kernel bk:
	docker 

build-image bi:
	docker run --rm \
		--name build-image \
		--volume ${PWD}/images:/build/images \
		--privileged \
		build-image \
		/bin/bash -c "./build-image.sh YES images/${FILE} && mv $(basename ${FILE})_* images/"
