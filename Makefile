.PHONY: docker-build docker-bash

JULIA_VERSION?=1.10.4
BASE_IMAGE?=ubuntu:20.04
IMAGE_NAME=tint_prj:v1
VOLUME=$(PWD):/work

docker-build:
	docker image build . --no-cache --tag ${IMAGE_NAME} \
	--build-arg BASE_IMAGE=${BASE_IMAGE} \
	--build-arg JULIA_VERSION=${JULIA_VERSION}

docker-bash:
	docker container run -p 8888:8888 -it -v ${VOLUME} --rm ${IMAGE_NAME} /bin/bash