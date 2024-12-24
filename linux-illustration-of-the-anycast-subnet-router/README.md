# Linux anycast subnet router
this Lab is a demonstration of how the anycast routing address of an IPv6 prefix works.

In the linux kernel, when you enable IPv6 forwarding, linux will take the first IPv6 of the network on which an IPv6 is configured (only applies to networks larger than /127).

How this address works is described here [RFC 4291][]

```
PC2# sysctl -w net.ipv6.conf.all.forwarding=0
PC2# ip route get 2001:db8:2::
2001:db8:2:: from :: dev eth1 proto kernel src 3fff:172:20:20::3 metric 256 pref medium

```
```
PC2# sysctl -w net.ipv6.conf.all.forwarding=1
PC2# ip route get 2001:db8:2::
anycast 2001:db8:2:: from :: dev lo table local proto kernel src 2001:db8:2::1 metric 0 pref medium
```

This behavior only becomes a problem if two machines have IPv6 forwarding enabled and need to communicate with each other, or if they don't know how to route the same thing or if, like me, you've configured a machine with the first address on the network.


[RFC 4291]: https://datatracker.ietf.org/doc/html/rfc4291#section-2.6.1
