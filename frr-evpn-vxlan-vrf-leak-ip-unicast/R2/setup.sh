#!/bin/bash

# Dummy
ip link add dummy0 type dummy
ip addr add 10.10.10.2/32 dev dummy0
ip link set up dev dummy0

# P2P to R2
ip addr add 10.0.0.2/30 dev eth1


# Add bridge and single vxlan device
ip link add vx0 type vxlan local 10.10.10.2 dstport 4789 external vnifilter nolearning
ip link add br0 type bridge vlan_filtering 1 vlan_stats_enabled 1 vlan_stats_per_port 1
ip link set vx0 master br0
ip link set vx0 type bridge_slave vlan_tunnel on neigh_suppress on learning off
ip link set br0 addr aa:bb:cc:00:00:02
ip link set br0 up
ip link set vx0 up

sysctl -qw net.ipv4.conf.vx0.forwarding=1
sysctl -qw net.ipv6.conf.vx0.forwarding=1


# L3 VRF
ip link add vrf1 type vrf table 100
ip link add vrf2 type vrf table 200
ip link set up vrf1
ip link set up vrf2

ip link add name l3vni100 link br0 type vlan id 100 protocol 802.1q
ip link add name l3vni200 link br0 type vlan id 200 protocol 802.1q
bridge vlan add vid 100 dev br0 self
bridge vlan add vid 200 dev br0 self
ip link set l3vni100 up
ip link set l3vni100 master vrf1
ip link set l3vni200 up
ip link set l3vni200 master vrf2
bridge vni add dev vx0 vni 100
bridge vni add dev vx0 vni 200
bridge vlan add dev vx0 vid 100 master
bridge vlan add dev vx0 vid 100 tunnel_info id 100 master
bridge vlan add dev vx0 vid 200 master
bridge vlan add dev vx0 vid 200 tunnel_info id 200 master

sysctl -qw net.ipv4.conf.l3vni100.forwarding=1
sysctl -qw net.ipv6.conf.l3vni100.forwarding=1
sysctl -qw net.ipv4.conf.l3vni200.forwarding=1
sysctl -qw net.ipv6.conf.l3vni200.forwarding=1

# L2 VNI 
ip link add name l2vni110 link br0 type vlan id 110 protocol 802.1q
bridge vlan add vid 110 dev br0 self
ip link set l2vni110 up
ip addr add 10.0.110.1/24 dev l2vni110
ip link set l2vni110 master vrf1
sysctl -qw net.ipv4.conf.l2vni110.forwarding=1

# add VNI / VLAN table
bridge vni add dev vx0 vni 110 
bridge vlan add dev vx0 vid 110 master
bridge vlan add dev vx0 vid 110 tunnel_info id 110 master

