#!/bin/bash
# fw = hub firewall, OUTSIDE the EVPN fabric. No VXLAN/EVPN.
# Wired ONLY to the spine: two plain VRFs, each with a unicast eBGP
# uplink to the spine -- eth1 -> HUBSVC uplink, eth2 -> SPKSVC uplink.
# Hub services are represented by a loopback inside HUBSVC (no host attached).

# Inter-spoke traffic hairpins HUBSVC -> SPKSVC through the firewall, which is
# asymmetric routing across VRFs. Disable RPF (kernel uses max(all,per-iface)).
sysctl -qw net.ipv4.conf.all.rp_filter=0
sysctl -qw net.ipv4.conf.default.rp_filter=0

# Loopback (BGP router-id)
ip link add dummy0 type dummy
ip addr add 192.0.2.2/32 dev dummy0
ip link set up dev dummy0

# VRFs (plain VRFs, no VNI / no VXLAN)
ip link add HUBSVC type vrf table 100
ip link set HUBSVC up
ip link add SPKSVC type vrf table 110
ip link set SPKSVC up

# HUBSVC uplink to spine (eth1)
ip link set eth1 master HUBSVC
ip addr add 192.0.2.17/31 dev eth1
ip -6 addr add 2001:db8:f0::1/127 dev eth1
ip link set eth1 up
sysctl -qw net.ipv4.conf.eth1.forwarding=1
sysctl -qw net.ipv6.conf.eth1.forwarding=1
sysctl -qw net.ipv4.conf.eth1.rp_filter=0

# Hub-services loopback inside HUBSVC (represents services reached via the hub;
# no external host/link -- the firewall connects only to the spine). Spokes
# reach it via the default route.
ip link add svc0 type dummy
ip link set svc0 master HUBSVC
ip addr add 203.0.113.1/32 dev svc0
ip -6 addr add 2001:db8:f::1/128 dev svc0
ip link set svc0 up

# SPKSVC uplink to spine (eth2)
ip link set eth2 master SPKSVC
ip addr add 192.0.2.19/31 dev eth2
ip -6 addr add 2001:db8:f1::1/127 dev eth2
ip link set eth2 up
sysctl -qw net.ipv4.conf.eth2.forwarding=1
sysctl -qw net.ipv6.conf.eth2.forwarding=1
sysctl -qw net.ipv4.conf.eth2.rp_filter=0
