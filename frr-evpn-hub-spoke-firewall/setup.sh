#!/usr/bin/env bash
P=clab-frr-evpn-hub-spoke-firewall

docker exec ${P}-spine /setup.sh
docker exec ${P}-fw   /setup.sh
docker exec ${P}-r1   /setup.sh
docker exec ${P}-r2   /setup.sh

# Configure the multitool hosts (no FRR; plain Linux addressing + default route)
while read container_name ip4 gw4 ip6 gw6; do
  docker exec -d "$container_name" sh -c "
    ip link set eth1 up &&
    ip addr add $ip4 dev eth1 &&
    ip -6 addr add $ip6 dev eth1 &&
    ip route replace default via $gw4 dev eth1 onlink &&
    ip -6 route replace default via $gw6 dev eth1 onlink
  "
done <<EOF
${P}-pc-a 198.51.100.2/28 198.51.100.1 2001:db8:a::2/64 2001:db8:a::1
${P}-pc-b 198.51.100.18/28 198.51.100.17 2001:db8:b::2/64 2001:db8:b::1
EOF
