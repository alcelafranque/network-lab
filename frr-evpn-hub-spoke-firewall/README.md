# frr-evpn-hub-spoke-firewall

Hub-and-spoke firewall lab. An EVPN/VXLAN type-5 fabric (spine + two spoke
routers) carries spoke subnets and a hub default; the **hub firewall sits
outside the fabric and attaches via a per-VRF unicast eBGP handoff** (a separate
link + BGP session per VRF, no EVPN/VXLAN overlay on the firewall).
Asymmetric route-targets + a firewall leak force all inter-spoke traffic to
hairpin through the firewall.

- **spine** (AS 65010): EVPN route-reflector **and border leaf** — terminates
  EVPN into local VRFs and stitches it to the firewall over plain unicast.
- **r1 / r2** (AS 65010): spoke routers, EVPN VTEPs. Two VRFs each: a **`spoke`**
  tenant VRF (L3VNI 110, where the PC attaches) and a **`HUBSVC`** services VRF
  (L3VNI 100). The tenant never imports a hub/peer route-target; instead its
  default route is a **leak (hop) from HUBSVC** — the standard shared-default-VRF
  pattern.
- **fw** (AS 65000): hub firewall, **no EVPN/VXLAN** — two VRF uplinks
  (HUBSVC, SPKSVC), unicast eBGP to the spine.

The router `spoke` VRF and the fabric/fw `SPKSVC` VRF share **L3VNI 110** and
route-target `65010:110`, so EVPN stitches them: the spoke tenant is collected
into the services VRF without the routers carrying the `SPKSVC` name. The hub
default lives in **HUBSVC** (L3VNI 100) on every node; tenant VRFs point their
default at it.

Documentation IP blocks only (RFC 5737 / RFC 3849). Verified on FRR 10.6.1.

## Topology

```
                    ┌──────────────────┐
   hub-svc lo ●─────│  fw   AS 65000    │  hub firewall — UNICAST only, no EVPN
  203.0.113.1       │ VRF HUBSVC  eth1  │──┐ HUBSVC uplink  (unicast eBGP v4+v6)
  (loopback in      │ VRF SPKSVC  eth2  │──┼─┐ SPKSVC uplink (unicast eBGP v4+v6)
   HUBSVC)          └──────────────────┘  │ │   (fw is wired ONLY to the spine)
                          ┌───────────────┘ │
                     eth1 │ eth4 ────────────┘
                    ┌─────┴────────────┐
                    │ spine  AS 65010  │  EVPN RR + BORDER LEAF (VTEP)
                    │ VRF HUBSVC vni100│  terminates EVPN <-> unicast handoff
                    │ VRF SPKSVC vni110│
                    └────┬────────┬────┘
             EVPN/VXLAN  │        │  EVPN/VXLAN   (underlay OSPF, lo↔lo)
              ┌──────────┘        └──────────┐
        ┌─────┴────────┐            ┌─────────┴────┐
        │ r1  AS 65010 │            │ r2  AS 65010 │  spoke routers (VTEPs)
        │ spoke  vni110│            │ spoke  vni110│  tenant VRF (PC attaches)
        │ HUBSVC vni100│            │ HUBSVC vni100│  default VRF; spoke default
        └─────┬────────┘            └───────┬──────┘  leaks (hops) into HUBSVC
           PC-A                          PC-B
```

## Addressing

Underlay (default VRF, OSPFv2 area 0, `dummy0` = VTEP source). **fw is not in the
underlay** — it reaches the fabric only over the per-VRF handoff links.

| Node  | Loopback     | underlay p2p |
|-------|--------------|--------------|
| spine | 192.0.2.1/32 | eth2 .10 / eth3 .12 (/31) |
| r1    | 192.0.2.3/32 | eth1 192.0.2.11/31 |
| r2    | 192.0.2.4/32 | eth1 192.0.2.13/31 |
| fw    | 192.0.2.2/32 | (router-id only) |

Per-VRF unicast handoff links (spine ⇄ fw), one per VRF:

| VRF | spine | fw | IPv6 (/127) |
|-----|-------|----|----|
| HUBSVC | eth1 192.0.2.16 | eth1 192.0.2.17 | spine `2001:db8:f0::` / fw `::1` |
| SPKSVC | eth4 192.0.2.18 | eth2 192.0.2.19 | spine `2001:db8:f1::` / fw `::1` |

Tenant subnets (dual-stack):

| Segment | VRF / node | IPv4 | IPv6 | gateway | host |
|---------|-----------|------|------|---------|------|
| Spoke A LAN | spoke / r1 | 198.51.100.0/28 | 2001:db8:a::/64 | .1 / ::1 | pc-a .2 / ::2 |
| Spoke B LAN | spoke / r2 | 198.51.100.16/28 | 2001:db8:b::/64 | .17 / ::1 | pc-b .18 / ::2 |
| Hub-services | HUBSVC / fw (loopback `svc0`) | 203.0.113.1/32 | 2001:db8:f::1/128 | — | — (no host; reached via default) |

## How it works

**The firewall speaks only unicast** (`router bgp 65000 vrf HUBSVC` / `vrf SPKSVC`,
no `l2vpn evpn`). The spine is the EVPN↔unicast border:

- **Default down:** fw HUBSVC `default-originate` → (unicast) → spine HUBSVC →
  `advertise ipv4/ipv6 unicast` injects it into EVPN as a type-5 with
  `route-target export 65010:100` (RT_HUB, L3VNI 100) → **r1/r2 HUBSVC** imports
  RT_HUB (next-hop = spine VTEP). The `spoke` tenant VRF then gets its default as
  a **leak from HUBSVC** (`import vrf HUBSVC`, default-only) — a hop into the
  services VRF, not a direct EVPN import.
- **Subnets up:** r1/r2 advertise their LAN as type-5 with `65010:110` (RT_SPK) →
  spine SPKSVC imports RT_SPK → (unicast) → fw SPKSVC **collects every spoke**.
- **Spoke isolation:** r1/r2 never import RT_SPK, so a spoke has no route to the
  other spoke — only the default. The spine HUBSVC has no spoke routes either,
  and the fw advertises **only the default** out HUBSVC (`route-map ... out`), so
  the leaked spoke routes are never re-injected into EVPN.
- **Inter-spoke hairpins through the firewall:** PC-A→PC-B follows the default to
  the spine, which forwards it (no specific route in HUBSVC) over the HUBSVC
  uplink to **fw**. fw `import vrf SPKSVC` gives it the route to PC-B, so it sends
  the packet back out the **SPKSVC** uplink to the spine, which encapsulates it
  to r2. Both directions cross the firewall. (RPF is disabled where this
  asymmetric cross-VRF hairpin occurs.)

## Deploy

```bash
sudo containerlab deploy -t clab.yaml --reconfigure
bash setup.sh
```

Allow ~30–60s for OSPF + EVPN + the per-VRF unicast sessions to converge.

## Verify

**spine — EVPN to the spokes** (the firewall is *not* an EVPN neighbor):

```console
$ docker exec clab-frr-evpn-hub-spoke-firewall-spine vtysh -c 'show bgp l2vpn evpn summary'
Neighbor        V         AS  ... State/PfxRcd
r1(192.0.2.3)   4      65010  ...            2
r2(192.0.2.4)   4      65010  ...            2
```

**fw — per-VRF unicast sessions to the spine, and it collects both spokes:**

```console
$ docker exec clab-frr-evpn-hub-spoke-firewall-fw vtysh -c 'show bgp vrf SPKSVC ipv4 unicast summary'
Neighbor          V         AS  ... State/PfxRcd
spine(192.0.2.18) 4      65010  ...            2

$ docker exec clab-frr-evpn-hub-spoke-firewall-fw vtysh -c 'show ip route vrf SPKSVC'
B>* 198.51.100.0/28  via 192.0.2.18, eth3      <- spoke A, via spine (unicast)
B>* 198.51.100.16/28 via 192.0.2.18, eth3      <- spoke B
```

**r1 — HUBSVC holds the hub default (EVPN, L3VNI 100); the `spoke` tenant's
default is a leak/hop into HUBSVC, and it has no route to the other spoke:**

```console
$ docker exec clab-frr-evpn-hub-spoke-firewall-r1 vtysh -c 'show ip route vrf HUBSVC 0.0.0.0/0'
  Known via "bgp", ... vrf HUBSVC, best
  * 192.0.2.1, via l3vni100 onlink              <- hub default via EVPN (spine VTEP, VNI 100)

$ docker exec clab-frr-evpn-hub-spoke-firewall-r1 vtysh -c 'show ip route vrf spoke'
B>* 0.0.0.0/0        via 192.0.2.1, l3vni100 (vrf HUBSVC) onlink   <- default = hop into HUBSVC
C>* 198.51.100.0/28  is directly connected, eth2                  <- own LAN (NO 198.51.100.16/28)
```

**fw HUBSVC — leaked spoke routes (`import vrf SPKSVC`) used for the hairpin:**

```console
$ docker exec clab-frr-evpn-hub-spoke-firewall-fw vtysh -c 'show ip route vrf HUBSVC'
B>* 198.51.100.0/28  via 192.0.2.18, eth3 (vrf SPKSVC)
B>* 198.51.100.16/28 via 192.0.2.18, eth3 (vrf SPKSVC)
C>* 203.0.113.1/32   is directly connected, svc0     <- hub-services loopback
```

**Data plane** (all dual-stack, 0% loss):

```bash
# inter-spoke (hairpins through the firewall)
docker exec clab-frr-evpn-hub-spoke-firewall-pc-a ping -c3 198.51.100.18
docker exec clab-frr-evpn-hub-spoke-firewall-pc-a ping -c3 2001:db8:b::2
# spoke -> hub-services loopback on the firewall, via the default
docker exec clab-frr-evpn-hub-spoke-firewall-pc-a ping -c3 203.0.113.1
docker exec clab-frr-evpn-hub-spoke-firewall-pc-a ping -c3 2001:db8:f::1
```

## Teardown

```bash
bash destroy.sh
```
