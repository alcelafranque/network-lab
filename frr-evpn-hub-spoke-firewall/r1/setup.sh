#!/bin/bash
ip link add dummy0 type dummy
ip addr add 192.0.2.3/32 dev dummy0
ip link set up dev dummy0

ip addr add 192.0.2.11/31 dev eth1
ip link set up dev eth1

ip link add vx0 type vxlan local 192.0.2.3 dstport 4789 external vnifilter nolearning
ip link add br0 type bridge vlan_filtering 1 vlan_stats_enabled 1 vlan_stats_per_port 1
ip link set vx0 master br0
ip link set vx0 type bridge_slave vlan_tunnel on neigh_suppress on learning off
ip link set br0 addr aa:bb:cc:00:00:03
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
HUBSVC 100
spoke 110
EOF

# HUBSVC (vni 100) carries the hub default via EVPN; no local interface here.
# Spoke-A LAN (eth2) in spoke
ip link set eth2 master spoke
ip addr add 198.51.100.1/28 dev eth2
ip -6 addr add 2001:db8:a::1/64 dev eth2
ip link set eth2 up
sysctl -qw net.ipv4.conf.eth2.forwarding=1
sysctl -qw net.ipv6.conf.eth2.forwarding=1
