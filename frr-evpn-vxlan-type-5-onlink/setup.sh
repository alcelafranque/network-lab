#!/bin/bash

docker exec clab-frr-evpn-vxlan-type-5-onlink-R1 /setup.sh
docker exec clab-frr-evpn-vxlan-type-5-onlink-R2 /setup.sh

docker exec clab-frr-evpn-vxlan-type-5-onlink-LB1 /setup.sh

while read container_name ip_address gateway ip_address6 gateway6; do
  docker exec -d "$container_name" sh -c "
    ip link set eth1 up &&
    ip addr add $ip_address dev eth1 &&
    ip -6 addr add $ip_address6 dev eth1 &&
    ip route replace default via $gateway dev eth1 onlink
    ip -6 route replace default via $gateway6 dev eth1 onlink
  "
done <<EOF
clab-frr-evpn-vxlan-type-5-onlink-PC1 10.2.0.2/32 10.2.0.1 2001:db8:2::2/128 2001:db8:2::
clab-frr-evpn-vxlan-type-5-onlink-PC2 10.3.0.2/32 10.3.0.1 2001:db8:3::2/128 2001:db8:3::
clab-frr-evpn-vxlan-type-5-onlink-PC3 10.2.0.3/32 10.2.0.1 2001:db8:2::3/128 2001:db8:2::
EOF
