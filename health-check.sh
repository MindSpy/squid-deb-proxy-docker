#!/bin/sh

proxy_port=${1:-8000}
listen_port=${2:-80}

# random token
token="$RANDOM"

set -ex 

# listen, wait for the token and check a response in a dettached process
test "$token" = "$(nc -l $listen_port)" &
# pid of dettached process
pid=$!

# after a while send token via proxy connect
sleep 1
nc -N -X connect -x 127.0.0.1:$proxy_port 127.0.0.1 $listen_port <<-EOF
$token
EOF

# wait for the detached process
wait $pid
