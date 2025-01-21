#!/bin/bash

# Dummy
ip link add dummy0 type dummy
ip addr add 203.0.113.1/32 dev dummy0
ip -6 addr add 2001:db8:cafe::1/128 dev dummy0
ip link set up dev dummy0
