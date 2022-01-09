#!/bin/bash

env_file=env.hcl
BUILDER_NAME=multiarch

for arg in "$@"; do
  case "$arg" in
    --env=*) 
        env_file="${arg#*=}"
        ;;
    --builder-name=*) 
        BUILDER_NAME="${arg#*=}"
        ;;
    --targets=*) 
        targets="${arg#*=}"
        ;;
    *)
        test "${arg}" != "--help" -a "${arg}" != "-h"  && printf "ERROR: unexpected argument: \"$arg\"\n"
        printf "\nUsage: $(basename $0) [OPTS]\n"
        printf "\nwhere [OPTS] can be:\n"
        printf "\t--env=[env file]  -  name of env file to source, default: env.hcl\n"
        printf "\t--builder-name=[name]  - name of builder to create (if not exists) and use, default: multiarch\n"
        printf "\t--targets=[list of targets]  - list of targets to build\n\n"
        printf "\tNote: In case the local git contains changes only a \"dev\" target is built\n"
        printf "\t      for a single arch \"linux/386\" with docker image tag of \"dev-DIRTY\".\n"
        printf "\t      A default docker builder is used for this purpose.\n"
        exit 
        ;;
    esac
done

test -e $env_file && source $env_file

set -ex

if ! docker buildx ls | grep ^$BUILDER_NAME -c > /dev/null 2>&1; then

    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    docker run --privileged --rm tonistiigi/binfmt --install all

    DRIVER_OPTS=""
    if [ -n "${PKG_PROXY_NET}" ]; then
        DRIVER_OPTS="--driver-opt network=${PKG_PROXY_NET}"
    fi

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
