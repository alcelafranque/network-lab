#!/bin/bash

# Dummy
ip link add dummy0 type dummy
ip addr add 10.10.10.1/32 dev dummy0
ip link set up dev dummy0

# P2P to R2
ip addr add 10.0.0.1/30 dev eth1


# Add bridge and single vxlan device
ip link add vx0 type vxlan local 10.10.10.1 dstport 4789 external vnifilter nolearning
ip link add br0 type bridge vlan_filtering 1 vlan_stats_enabled 1 vlan_stats_per_port 1
ip link set vx0 master br0
ip link set vx0 type bridge_slave vlan_tunnel on neigh_suppress on learning off
ip link set br0 addr aa:bb:cc:00:00:01
ip link set br0 up
ip link set vx0 up

sysctl -qw net.ipv4.conf.vx0.forwarding=1
sysctl -qw net.ipv6.conf.vx0.forwarding=1

sysctl -qw net.ipv4.conf.br0.forwarding=1
sysctl -qw net.ipv6.conf.br0.forwarding=1

# L3 VRF
while read vrf table; do
    ip link add $vrf type vrf table $table
    ip link set $vrf up
    ip link add name l3vni$table link br0 type vlan id $table protocol 802.1q
    bridge vlan add vid $table dev br0 self
    ip link set l3vni$table up
    ip link set l3vni$table master $vrf
    bridge vni add dev vx0 vni $table
    bridge vlan add dev vx0 vid $table master
    bridge vlan add dev vx0 vid $table tunnel_info id $table master
    sysctl -qw net.ipv4.conf.l3vni$table.forwarding=1
    sysctl -qw net.ipv6.conf.l3vni$table.forwarding=1
done <<EOF
vrf1 100
vrf2 200
EOF

while read iface local_ip local_ip6 vrf vni; do
# L2 VNI 
ip link add name l2vni$vni link br0 type vlan id $vni protocol 802.1q
bridge vlan add vid $vni dev br0 self
ip link set l2vni$vni up
ip addr add $local_ip dev l2vni$vni
ip -6 addr add $local_ip6 dev l2vni$vni
ip link set l2vni$vni master $vrf
sysctl -qw net.ipv4.conf.l2vni$vni.forwarding=1

# add VNI / VLAN table
bridge vni add dev vx0 vni $vni 
bridge vlan add dev vx0 vid $vni master
bridge vlan add dev vx0 vid $vni tunnel_info id $vni master

# LB1
ip link set $iface master br0
bridge vlan add dev $iface vid $vni master pvid untagged

done <<EOF
eth2 10.0.110.1/24 2001:db8:110::/64 vrf1 110
EOF

