#!/bin/bash

# Dummy
ip link add dummy0 type dummy
ip addr add 10.0.0.1/32 dev dummy0
ip link set up dev dummy0
