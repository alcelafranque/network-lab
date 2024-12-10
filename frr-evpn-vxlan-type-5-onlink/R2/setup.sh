#!/bin/bash

# Dummy
ip link add dummy0 type dummy
ip addr add 10.0.0.2/32 dev dummy0
ip link set up dev dummy0

# P2P to R2
ip addr add 100.64.0.2/30 dev eth1


# Add bridge and single vxlan device
ip link add vx0 type vxlan local 10.0.0.2 dstport 4789 external vnifilter nolearning
ip link add br0 type bridge vlan_filtering 1 vlan_stats_enabled 1 vlan_stats_per_port 1
ip link set vx0 master br0
ip link set vx0 type bridge_slave vlan_tunnel on neigh_suppress on learning off
ip link set br0 addr aa:bb:cc:00:00:02
ip link set br0 up
ip link set vx0 up

sysctl -qw net.ipv4.conf.vx0.forwarding=1
sysctl -qw net.ipv6.conf.vx0.forwarding=1

sysctl -qw net.ipv4.conf.br0.forwarding=1
sysctl -qw net.ipv6.conf.br0.forwarding=1


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
purple 100
red 200
blue 300
EOF

while read iface local_ip vrf nei_ip; do
    ip link set $iface up
    ip link set $iface master $vrf
    ip addr add $local_ip dev $iface
    ip route add $nei_ip dev $iface proto static vrf $vrf
    sysctl -qw net.ipv4.conf.$iface.forwarding=1
done <<EOF
eth3 10.2.0.1/32 red 10.2.0.3/32
EOF
