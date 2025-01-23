# FRR EVPN VXLAN, loadbalancer with bgp ipv-unicast session and export in EVPN RT5

A loadbalancer is present on this lab, announcing an IPv4 in the vrf1 with an BGP session with R1.
This announcement is propagated as a type 5 route, and is found in the other vrfs by the RT import behavior.

Please note, the leak does not work on R1, I think is a bug on the FRR side.

```console
R1# show ip route vrf vrf1
Codes: K - kernel route, C - connected, L - local, S - static,
       R - RIP, O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric, t - Table-Direct,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

VRF vrf1:
C>* 10.0.110.0/24 is directly connected, l2vni110, 00:00:14
L>* 10.0.110.1/32 is directly connected, l2vni110, 00:00:14
B>* 203.0.113.1/32 [200/0] via 10.0.110.2, l2vni110, weight 1, 00:00:09
```

But on the vrf2 locally on R1 :
```console
R1# show ip route vrf vrf2
Codes: K - kernel route, C - connected, L - local, S - static,
       R - RIP, O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric, t - Table-Direct,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

VRF vrf2:
B>* 10.0.110.0/24 [200/0] via 10.10.10.2, vx0 (vrf default) onlink, label 100, weight 1, 00:00:47
```

however, if we look at R2, it seems to work.

```console
R2# show ip route vrf vrf1
Codes: K - kernel route, C - connected, L - local, S - static,
       R - RIP, O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric, t - Table-Direct,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

VRF vrf1:
C>* 10.0.110.0/24 is directly connected, l2vni110, 00:02:04
L>* 10.0.110.1/32 is directly connected, l2vni110, 00:02:04
B>* 10.0.110.2/32 [200/0] via 10.10.10.1, l3vni100 onlink, weight 1, 00:02:01
B>* 203.0.113.1/32 [200/0] via 10.10.10.1, l3vni100 onlink, weight 1, 00:02:00
R2#
```

```console
R2# show ip route vrf vrf2
Codes: K - kernel route, C - connected, L - local, S - static,
       R - RIP, O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric, t - Table-Direct,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

VRF vrf2:
B>* 10.0.110.0/24 [200/0] via 10.10.10.1, vx0 (vrf default) onlink, label 100, weight 1, 00:02:08
B>* 10.0.110.2/32 [200/0] via 10.10.10.1, vx0 (vrf default) onlink, label 100, weight 1, 00:02:08
B>* 203.0.113.1/32 [200/0] via 10.10.10.1, vx0 (vrf default) onlink, label 100, weight 1, 00:02:07
```

