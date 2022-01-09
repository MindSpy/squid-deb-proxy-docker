#!/bin/sh

proxy_port=${1:-8000}
listen_port=${2:-80}

listen_check() {
    # listens and waits for connection
    reponse=$(nc -l $1) 
    # checks the response
    test "$2" = "$reponse"
}

set -ex 

# random token
token="$RANDOM"
# listen and check the token dettached
listen_check $listen_port $token & 
# pid of dettached process
pid=$!

# after a while send token via proxy connect
sleep 1
nc -N -X connect -x 127.0.0.1:$proxy_port 127.0.0.1 $listen_port <<-EOF
$token
EOF

# wait for detached process
wait $pid
