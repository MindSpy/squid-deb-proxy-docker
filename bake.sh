#!/bin/bash

test -e env.hcl && source env.hcl


BUILDER_NAME=multiarch
DRIVER_OPTS=""
if [ -n "${PKG_PROXY_NET}" ]; then
    DRIVER_OPTS="--driver-opt network=${PKG_PROXY_NET}"
fi

set -ex

if ! docker buildx ls | grep ^$BUILDER_NAME -c > /dev/null; then

    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    docker run --privileged --rm tonistiigi/binfmt --install all

    #docker buildx rm $BUILDER_NAME
    docker buildx create --name $BUILDER_NAME --use --driver docker-container $DRIVER_OPTS
    docker buildx inspect --bootstrap

fi

# docker buildx bake -f env.hcl -f docker-bake.hcl --push  --no-cache --progress=plain latest
docker buildx bake -f env.hcl -f docker-bake.hcl --push $targets
# docker buildx rm multiarch