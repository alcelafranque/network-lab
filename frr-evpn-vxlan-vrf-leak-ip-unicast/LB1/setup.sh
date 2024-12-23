#!/bin/bash

# Dummy
ip link add dummy0 type dummy
ip addr add 203.0.113.1/32 dev dummy0
ip -6 addr add 2001:db8:1::2/128 dev dummy0
ip link set up dev dummy0

# P2P to R1
ip addr add 10.0.110.2/24 dev eth1
ip link set up dev eth1
