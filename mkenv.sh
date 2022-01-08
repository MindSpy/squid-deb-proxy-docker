#!/bin/bash

for arg in "$@"; do
  case "$arg" in
    --flavor=*) 
        flavor="${arg#*=}"
        ;;
    --pkg-proxy=*) 
        PKG_PROXY="${arg#*=}"
        ;;
    --pkg-proxy-net=*) 
        PKG_PROXY_NET="${arg#*=}"
        ;;
    --pkg-proxy-cont=*) 
        proxy_cont="${arg#*=}"
        ;;
    *)
        echo "Usage: $0 [options]"
        echo "  where [options] are:"
        echo "    --flavor=(env|args|compose)  -  output flavor, default: env"
        echo "    --pkg-proxy=[url]  - package proxy url e.g. squid-deb-proxy"
        echo "    --pkg-proxy-net=[docker network name]  - name of docker network where proxy listens"
        echo "    --pkg-proxy-cont=[docker container name]  - container name from which autodetect the proxy and network arguments"
        exit 
        ;;
    esac
done


if [ -n "$(git status -s)" ]; then
  GIT_BRANCH=DIRTY 
else 
  GIT_BRANCH=$(git rev-parse --short HEAD)
fi

if [ -n "$proxy_cont" ]; then

  if [ -n "$PKG_PROXY" -o  -n "$PKG_PROXY_NET" ]; then
    echo "Argument  --pkg-proxy-cont cannot be used with --pkg-proxy or --pkg-proxy-net ."
  fi

  # autodetect container network, IP address and port
  cont_nets=($(docker inspect $proxy_cont -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{$v.IPAddress}}{{end}}'))
  cont_ports=($(docker inspect $proxy_cont -f '{{range $k,$v := .NetworkSettings.Ports}}{{$k}} {{end}}'))

  # obtain forst TCP port
  for p in "${cont_ports[@]}"; do
    if [ "${p#*/}" == "tcp" ]; then
      cont_port="${p%/*}"
      break
    fi
  done
  
  # use first network an assigned IP address and port
  PKG_PROXY=http://${cont_nets[1]}:$cont_port
  PKG_PROXY_NET=${cont_nets[0]}
fi


declare -A values

values[GIT_BRANCH]="$GIT_BRANCH"
values[BUILD_DATE]="$(date +%Y%m%d)"
values[USE_ACL]="0"
values[USE_AVAHI]="0"
values[PKG_PROXY]="$PKG_PROXY"
values[PKG_PROXY_NET]="$PKG_PROXY_NET"
values[TARGETPLATFORM]="linux/amd64"

case "${flavor:-env}" in
env)

for k in "${!values[@]}"; do
  v="${values[$k]}"
  if [ -n "$v" ]; then 
    printf "%s=\"%s\"\n" "$k" "$v"
  fi
done 

;;

compose)

for k in "${!values[@]}"; do
  v="${values[$k]}"
  if [ -n "$v" ]; then 
    # no quotes around the values
    printf "%s=%s\n" "$k" "$v"
  fi
done 

;;
args)

for k in "${!values[@]}"; do
  v="${values[$k]}"
  if [ -n "$v" ]; then 
    # no quotes around the values
    printf '%s %s=%s '  '--build-arg' "$k" "$v"
  fi
done
printf "\n" 

;;
esac




