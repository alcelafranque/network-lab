#!/bin/bash
# spine = EVPN route-reflector + border leaf (VTEP).
# Fabric side (eth2/eth3): underlay + EVPN to r1/r2.
# Firewall side (eth1/eth4): per-VRF unicast handoff, one link per VRF.

# Inter-spoke traffic hairpins through the firewall, so routing across VRFs is
# asymmetric. Disable RPF (kernel uses max(all,per-interface)). 'all' is the
# backstop; 'default' covers vx0/l3vni/VRF devices created below; the pre-existing
# ethN ports (made by containerlab before this script) get explicit lines later.
sysctl -qw net.ipv4.conf.all.rp_filter=0
sysctl -qw net.ipv4.conf.default.rp_filter=0

# Loopback (VTEP source + OSPF router-id + EVPN update-source)
ip link add dummy0 type dummy
ip addr add 192.0.2.1/32 dev dummy0
ip link set up dev dummy0

# Underlay p2p links to the spokes
ip addr add 192.0.2.10/31 dev eth2  # to r1
ip addr add 192.0.2.12/31 dev eth3  # to r2
ip link set up dev eth2
ip link set up dev eth3

# VXLAN + bridge (spine terminates EVPN into local VRFs)
ip link add vx0 type vxlan local 192.0.2.1 dstport 4789 external vnifilter nolearning
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

# L3 VRFs / L3VNIs (table id == vlan id == vni)
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
SPKSVC 110
EOF

# Per-VRF unicast handoff links to the firewall
ip link set eth1 master HUBSVC
ip addr add 192.0.2.16/31 dev eth1
ip -6 addr add 2001:db8:f0::/127 dev eth1
ip link set eth1 up
sysctl -qw net.ipv4.conf.eth1.forwarding=1
sysctl -qw net.ipv6.conf.eth1.forwarding=1
sysctl -qw net.ipv4.conf.eth1.rp_filter=0

ip link set eth4 master SPKSVC
ip addr add 192.0.2.18/31 dev eth4
ip -6 addr add 2001:db8:f1::/127 dev eth4
ip link set eth4 up
sysctl -qw net.ipv4.conf.eth4.forwarding=1
sysctl -qw net.ipv6.conf.eth4.forwarding=1
sysctl -qw net.ipv4.conf.eth4.rp_filter=0

# Belt-and-suspenders RPF disable on the VTEP datapath interfaces
sysctl -qw net.ipv4.conf.vx0.rp_filter=0
sysctl -qw net.ipv4.conf.eth2.rp_filter=0
sysctl -qw net.ipv4.conf.eth3.rp_filter=0
