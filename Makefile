.PHONY: docker-build docker-bash
include .env

JULIA_VERSION?=1.10.4
BASE_IMAGE?=ubuntu:20.04
IMAGE_NAME=tint_prj:v1
VOLUME=$(PWD):/work

docker-build:
	docker image build . --no-cache --tag ${IMAGE_NAME} \
	--build-arg git_username=${git_username} \
	--build-arg git_email=${git_email}

docker-bash:
	docker container run -p 8888:8888 -it -v ${VOLUME} --rm ${IMAGE_NAME} /bin/bash