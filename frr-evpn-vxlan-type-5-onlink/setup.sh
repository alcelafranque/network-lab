#!/bin/bash

docker exec clab-frr-evpn-vxlan-type-5-onlink-R1 /setup.sh
docker exec clab-frr-evpn-vxlan-type-5-onlink-R2 /setup.sh

docker exec clab-frr-evpn-vxlan-type-5-onlink-LB1 /setup.sh
