#!/bin/bash

# intial configuration
while read container_name ip_address ip_address6; do
  docker exec -d "$container_name" sh -c "
    ip link set eth1 up &&
    ip addr add $ip_address dev eth1 &&
    ip -6 addr add $ip_address6 dev eth1
  "
done <<EOF
clab-linux-illustration-of-the-anycast-subnet-router-PC1 10.2.0.1/24 2001:db8:2::/64
clab-linux-illustration-of-the-anycast-subnet-router-PC2 10.2.0.2/24 2001:db8:2::1/64
EOF

# test the initial configuration
while read container_name; do
  if [[ "$container_name" == "clab-linux-illustration-of-the-anycast-subnet-router-PC2" ]]; then
    echo "Running commands for $container_name" before ipv6 forwarding
    docker exec "$container_name" sh -c "
      ip route get 2001:db8:2::
    "
  fi
done <<EOF
clab-linux-illustration-of-the-anycast-subnet-router-PC1
clab-linux-illustration-of-the-anycast-subnet-router-PC2
EOF

# activate ipv6 forwarding on both PC
while read container_name ip_address ip_address6; do
  docker exec -d "$container_name" sh -c "
    sysctl -w net.ipv6.conf.all.forwarding=1
  "
done <<EOF
clab-linux-illustration-of-the-anycast-subnet-router-PC1
clab-linux-illustration-of-the-anycast-subnet-router-PC2
EOF

# finnaly show the route for PC1 on PC2
sleep 3
echo "Running commands for clab-linux-illustration-of-the-anycast-subnet-router-PC2 route get after ipv6 forwarding"
docker exec clab-linux-illustration-of-the-anycast-subnet-router-PC2 sh -c "ip route get 2001:db8:2::"
