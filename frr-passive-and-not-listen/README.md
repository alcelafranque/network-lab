# FRR BGP/BFD WITH ONE PASSIVE PEER AND ANOTHER PEER DONT LISTEN BGP

In this lab, we have a router configured in peer-group mode on an IPv6 subnet. 
On the other side, we have a load balancer configured not to listen,on 
port 179 for BGP. We have BFD between the two peers.

```console
LB1# show bgp sum

IPv4 Unicast Summary:
Neighbor        V         AS   MsgRcvd   MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd   PfxSnt Desc
R1(2001:db8::1) 4      64600         9        10        1    0    0 00:00:15            0        1 FRRouting/10.2.1_git

Total number of neighbors 1

IPv6 Unicast Summary:
Neighbor        V         AS   MsgRcvd   MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd   PfxSnt Desc
R1(2001:db8::1) 4      64600         9        10        0    0    0 00:00:15            0        0 FRRouting/10.2.1_git

Total number of neighbors 1
```

```console
R1# show bgp sum

IPv4 Unicast Summary:
Neighbor          V         AS   MsgRcvd   MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd   PfxSnt Desc
*LB1(2001:db8::2) 4      64600        22        21        2    0    0 00:00:51            1        0 FRRouting/10.2.1_git

Total number of neighbors 1
* - dynamic neighbor
1 dynamic neighbor(s), limit 100

IPv6 Unicast Summary:
Neighbor          V         AS   MsgRcvd   MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd   PfxSnt Desc
*LB1(2001:db8::2) 4      64600        22        21        3    0    0 00:00:51            0        0 FRRouting/10.2.1_git
```

```console
LB1# show bfd peer
BFD Peers:
	peer 2001:db8::1 local-address 2001:db8::2 vrf default interface eth1
		ID: 4087184927
		Remote ID: 4087184927
		Active mode
		Status: up
		Uptime: 1 minute(s), 55 second(s)
		Diagnostics: ok
		Remote diagnostics: ok
		Peer Type: dynamic
		RTT min/avg/max: 0/0/0 usec
		Local timers:
			Detect-multiplier: 3
			Receive interval: 300ms
			Transmission interval: 300ms
			Echo receive interval: 50ms
			Echo transmission interval: disabled
		Remote timers:
			Detect-multiplier: 3
			Receive interval: 300ms
			Transmission interval: 300ms
			Echo receive interval: 50ms
```


```console
R1# show bfd peers
BFD Peers:
	peer 2001:db8::2 local-address 2001:db8::1 vrf default interface eth1
		ID: 4087184927
		Remote ID: 4087184927
		Active mode
		Status: up
		Uptime: 1 minute(s), 33 second(s)
		Diagnostics: ok
		Remote diagnostics: ok
		Peer Type: dynamic
		RTT min/avg/max: 0/0/0 usec
		Local timers:
			Detect-multiplier: 3
			Receive interval: 300ms
			Transmission interval: 300ms
			Echo receive interval: 50ms
			Echo transmission interval: disabled
		Remote timers:
			Detect-multiplier: 3
			Receive interval: 300ms
			Transmission interval: 300ms
			Echo receive interval: 50ms
```

