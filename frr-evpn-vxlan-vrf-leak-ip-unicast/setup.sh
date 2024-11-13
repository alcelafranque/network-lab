#!/bin/bash

docker exec clab-frr01-R1 /setup.sh
docker exec clab-frr01-R2 /setup.sh

docker exec clab-frr01-LB1 /setup.sh
