#!/bin/bash

# Add addr
ip addr add 10.0.220.2/24 dev eth1

# Add default GW via R1
ip route del default
ip route add default via 10.0.220.1 dev eth1
