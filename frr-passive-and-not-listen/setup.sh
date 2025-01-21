#!/bin/bash

docker exec clab-frr-passive-and-not-listen-R1 /setup.sh
docker exec clab-frr-passive-and-not-listen-LB1 /setup.sh

while read container_name ip_address ip_address6; do
  docker exec -d "$container_name" sh -c "
    ip link set eth1 up &&
    ip addr add $ip_address dev eth1 &&
    ip -6 addr add $ip_address6 dev eth1
  "
done <<EOF
clab-frr-passive-and-not-listen-R1 10.1.0.1/24 2001:db8::1/64
clab-frr-passive-and-not-listen-LB1 10.1.0.2/24 2001:db8::2/64
EOF
