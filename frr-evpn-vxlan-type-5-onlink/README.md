# FRR EVPN VXLAN, VRF leaking and type 5 routes

This lab is similar in part to Vincent Bernat's [lab-frr-evpn-vrf][]

The goal isn't quite the same: in Vincent's lab we had prefixes, type 5 route on [access interfaces][].

However, if a machine on router 1 with the same prefix as a second machine on router 2 wants to communicate, it will need L2 continuity. 
In this case, this worked with type 2 routes.

This mode can cause scaling problems, as we can see a lot of BUM traffic on large infrastructures. 
In my case, I wanted to test the use of local static route redistribution.

Here we see a route in vrf purple to a machine in VRF RED, so the leak is working properly.

```
R1# show ip bgp vrf purple 10.2.0.3/32
BGP routing table entry for 10.2.0.3/32, version 3
Paths: (1 available, best #1, vrf purple)
  Not advertised to any peer
  Imported from 10.0.0.2:3:[5]:[0]:[32]:[10.2.0.3], VNI 200
  Local
    10.0.0.2(R2) from R2(100.64.0.2) (10.0.0.2) announce-nh-self
      Origin incomplete, metric 0, localpref 100, valid, internal, bestpath-from-AS Local, best (First path received)
      Extended Community: RT:64600:200 ET:8 Rmac:aa:bb:cc:00:00:02

R1# show ip route vrf purple 10.2.0.3/32
Routing entry for 10.2.0.3/32
  Known via "bgp", distance 200, metric 0, vrf purple, best
  Last update 00:03:32 ago
  * 10.0.0.2, via vx0(vrf default) onlink, label 200, weight 1
```

A loadbalancer is also present on this lab, announcing an IPv4 in the purple vrf with an BGP session with R1.
This announcement is propagated as a type 5 route, and is found in the other vrfs by the same RT import behavior.

Please note, the leak does not work on R1, I think is a bug on the FRR side. I'm planning to open an issue.

```
R1# show ip route vrf purple 203.0.113.1/32
Routing entry for 203.0.113.1/32
  Known via "bgp", distance 200, metric 0, vrf purple, best
  Last update 00:21:09 ago
    10.1.0.2 (recursive), weight 1
  *   10.1.0.2, via eth2 onlink, weight 1

R1# show ip route vrf red 203.0.113.1/32
% Network not in table
```

```
R2# show ip route vrf purple 203.0.113.1/32
Routing entry for 203.0.113.1/32
  Known via "bgp", distance 200, metric 0, vrf purple, best
  Last update 00:22:07 ago
  * 10.0.0.1, via l3vni100 onlink, weight 1

R2# show ip route vrf red 203.0.113.1/32
Routing entry for 203.0.113.1/32
  Known via "bgp", distance 200, metric 0, vrf red, best
  Last update 00:22:18 ago
  * 10.0.0.1, via vx0(vrf default) onlink, label 100, weight 1
```

[lab-frr-evpn-vrf]: https://github.com/vincentbernat/network-lab/tree/master/lab-frr-evpn-vrf
[access interfaces]: https://github.com/vincentbernat/network-lab/blob/master/lab-frr-evpn-vrf/setup#L69
