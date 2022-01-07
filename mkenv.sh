#!/bin/bash

evnfile=.env

if [ -n "$(git status -s)" ]; then
  GIT_BRANCH=DIRTY 
else 
  GIT_BRANCH=$(git rev-parse --short HEAD)
fi

cat <<-EOF
GIT_BRANCH=$GIT_BRANCH
BUILD_DATE=$(date +%Y%m%d)
USE_ACL=0
USE_AVAHI=0
platform=linux/amd64
EOF



