#!/bin/bash

# Dummy
ip link add dummy0 type dummy
ip addr add 203.0.113.1/32 dev dummy0
ip -6 addr add 2001:db8:cafe::1/128 dev dummy0
ip link set up dev dummy0

# P2P to R1
ip addr add 10.1.0.2/32 dev eth1
ip -6 addr add 2001:db8:1::2/128 dev eth1
ip link set up dev eth1
ip route replace default via 10.1.0.1 dev eth1 onlink
ip -6 route replace default via 2001:db8:1:: dev eth1 onlink
