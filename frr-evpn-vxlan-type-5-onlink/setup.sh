#!/bin/bash

docker exec clab-frr-evpn-vxlan-type-5-onlink-R1 /setup.sh
docker exec clab-frr-evpn-vxlan-type-5-onlink-R2 /setup.sh

docker exec clab-frr-evpn-vxlan-type-5-onlink-LB1 /setup.sh

while read container_name ip_address gateway; do
  docker exec -d "$container_name" sh -c "
    ip link set eth1 up &&
    ip addr add $ip_address dev eth1 &&
    ip route replace default via $gateway dev eth1 onlink
  "
done <<EOF
clab-frr-evpn-vxlan-type-5-onlink-PC1 10.2.0.2/32 10.2.0.1
clab-frr-evpn-vxlan-type-5-onlink-PC2 10.3.0.2/32 10.3.0.1
clab-frr-evpn-vxlan-type-5-onlink-PC3 10.2.0.3/32 10.2.0.1
EOF
