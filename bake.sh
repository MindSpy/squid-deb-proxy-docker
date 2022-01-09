#!/bin/bash

test -e env.hcl && source env.hcl

BUILDER_NAME=multiarch
DRIVER_OPTS=""
if [ -n "${PKG_PROXY_NET}" ]; then
    DRIVER_OPTS="--driver-opt network=${PKG_PROXY_NET}"
fi

set -ex

if ! docker buildx ls | grep ^$BUILDER_NAME -c > /dev/null 2>&1; then

    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    docker run --privileged --rm tonistiigi/binfmt --install all

    #docker buildx rm $BUILDER_NAME
    docker buildx create --name $BUILDER_NAME --use --driver docker-container $DRIVER_OPTS
    docker buildx inspect --bootstrap

fi

if [ -n "$(git status -s)" ]; then
  GIT_BRANCH=DIRTY 
else 
  GIT_BRANCH=$(git rev-parse --short HEAD)
fi

BUILD_DATE="$(date +%Y%m%d)"

BAKE_ARGS="-f env.hcl -f docker-bake.hcl"

if [ -z "${GIT_BRANCH}" -o "${GIT_BRANCH}" == "DIRTY" ]; then
  BAKE_ARGS="$BAKE_ARGS --progress=plain --builder default --set *.output=type=image --set *.platform=linux/386 dev"
else
  BAKE_ARGS="$BAKE_ARGS --push $targets"
fi

docker buildx bake $BAKE_ARGS

# docker buildx rm multiarch