#!/bin/bash

# Dummy
ip link add dummy0 type dummy
ip addr add 10.0.0.1/32 dev dummy0
ip link set up dev dummy0

# P2P to R2
ip addr add 100.64.0.1/30 dev eth1


# Add bridge and single vxlan device
ip link add vx0 type vxlan local 10.0.0.1 dstport 4789 external vnifilter nolearning
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
ip link add purple type vrf table 100
ip link add red type vrf table 200
ip link add blue type vrf table 300
ip link set purple up 
ip link set red  up 
ip link set blue up 

ip link add name l3vni100 link br0 type vlan id 100 protocol 802.1q
ip link add name l3vni200 link br0 type vlan id 200 protocol 802.1q
ip link add name l3vni300 link br0 type vlan id 300 protocol 802.1q
bridge vlan add vid 100 dev br0 self
bridge vlan add vid 200 dev br0 self
bridge vlan add vid 300 dev br0 self
ip link set l3vni100 up
ip link set l3vni100 master purple
ip link set l3vni200 up
ip link set l3vni200 master red
ip link set l3vni300 up
ip link set l3vni300 master blue
bridge vni add dev vx0 vni 100
bridge vni add dev vx0 vni 200
bridge vni add dev vx0 vni 300
bridge vlan add dev vx0 vid 100 master
bridge vlan add dev vx0 vid 100 tunnel_info id 100 master
bridge vlan add dev vx0 vid 200 master
bridge vlan add dev vx0 vid 200 tunnel_info id 200 master
bridge vlan add dev vx0 vid 300 master
bridge vlan add dev vx0 vid 300 tunnel_info id 300 master

sysctl -qw net.ipv4.conf.l3vni100.forwarding=1
sysctl -qw net.ipv6.conf.l3vni100.forwarding=1
sysctl -qw net.ipv4.conf.l3vni200.forwarding=1
sysctl -qw net.ipv6.conf.l3vni200.forwarding=1
sysctl -qw net.ipv4.conf.l3vni300.forwarding=1
sysctl -qw net.ipv6.conf.l3vni300.forwarding=1

# LB1
ip link set eth2 up
ip link set eth2 master purple
ip addr add 10.1.0.1/32 dev eth2
ip route add 10.1.0.2/32 nexthop dev eth2
sysctl -qw net.ipv4.conf.eth2.forwarding=1

# PC1
ip link set eth3 up
ip link set eth3 master red
ip addr add 10.2.0.1/32 dev eth3
ip route add 10.2.0.2/32 nexthop dev eth3
sysctl -qw net.ipv4.conf.eth3.forwarding=1

# PC2
ip link set eth4 up
ip link set eth4 master red
ip addr add 10.3.0.1/32 dev eth4
ip route add 10.3.0.2/32 nexthop dev eth4
sysctl -qw net.ipv4.conf.eth4.forwarding=1

