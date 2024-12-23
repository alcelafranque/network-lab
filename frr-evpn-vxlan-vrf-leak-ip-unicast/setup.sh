#!/bin/bash

docker exec clab-frr-evpn-vxlan-vrf-leak-ip-unicast-R1 /setup.sh
docker exec clab-frr-evpn-vxlan-vrf-leak-ip-unicast-R2 /setup.sh

docker exec clab-frr-evpn-vxlan-vrf-leak-ip-unicast-LB1 /setup.sh
