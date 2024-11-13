# Debugging FRR with GDB and Containerlab

First, we will need a container image that includes the debug symbols for FRR.

We will build it using this Dockerfile:
```
FROM debian:bookworm

ENV DEBIAN_FRONTEND noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

RUN apt-get update && \
    apt-get install -y libpcre3-dev apt-transport-https ca-certificates curl wget logrotate \
    libc-ares2 libjson-c5 vim procps libreadline8 gnupg2 lsb-release apt-utils \
    libprotobuf-c-dev protobuf-c-compiler tini && rm -rf /var/lib/apt/lists/*

RUN curl -s https://deb.frrouting.org/frr/keys.asc | apt-key add -
RUN echo deb https://deb.frrouting.org/frr $(lsb_release -s -c) frr-stable | tee -a /etc/apt/sources.list.d/frr.list

RUN apt-get update && \
    apt-get install -y frr frr-pythontools frr-dbgsym gdb && \
    rm -rf /var/lib/apt/lists/*

# Own the config / PID files
RUN mkdir -p /var/run/frr
RUN chown -R frr:frr /etc/frr /var/run/frr

# Simple init manager for reaping processes and forwarding signals
ENTRYPOINT ["/usr/bin/tini", "--"]

# Default CMD starts watchfrr
COPY --chmod=0755 docker-start /usr/lib/frr/docker-start
CMD ["/usr/lib/frr/docker-start"]

```

This is a modified version of the file from [FRRouting Dockerfile](https://github.com/FRRouting/frr/blob/master/docker/debian/Dockerfile). We updated the image to include a recent version of `iproute2` that supports VXLAN devices with VNIFILTER. (See [this commit](https://github.com/iproute2/iproute2/commit/45cd32f9f7d53087b48b76e0a880066fd7ea77a6)).

The second modification is the addition of the `frr-dbgsym` package.

Once the build is complete, we can use the image in our lab. 
With the container running our FRR, it is possible to attach to the `bgpd` process.
```
root@R1:/# ps aux
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0   2472  1048 pts/0    Ss   18:41   0:00 /usr/bin/tini -- /usr/lib/frr/docker-start
root           7  0.0  0.0   4188  3156 pts/0    S+   18:41   0:00 /bin/bash /usr/lib/frr/docker-start
frr           30  0.0  0.0 190588 13412 ?        Ssl  18:41   0:00 /usr/lib/frr/bgpd -d -F traditional --daemon -A 127.0.0.1
root         140  0.0  0.0   4188  3228 pts/1    Ss   18:43   0:00 /bin/bash
root         183  0.0  0.0   8104  3744 pts/1    R+   18:45   0:00 ps aux
```


```
root@R1:/# gdb -p 30
GNU gdb (Debian 13.1-3) 13.1
Copyright (C) 2023 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This GDB was configured as "x86_64-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<https://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
    <http://www.gnu.org/software/gdb/documentation/>.

For help, type "help".
Type "apropos word" to search for commands related to "word".
Attaching to process 30
[New LWP 31]
[New LWP 32]
[New LWP 33]
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".
0x00007f4d6471b2d6 in __ppoll (fds=0x7f4d6413b010, nfds=nfds@entry=12, timeout=<optimized out>, sigmask=sigmask@entry=0x7fff5577b930) at ../sysdeps/unix/sysv/linux/ppoll.c:42
42	../sysdeps/unix/sysv/linux/ppoll.c: No such file or directory.
(gdb) bt
```

We can verify the thread to which we are attached.
```
(gdb) info threads
  Id   Target Id                                    Frame
* 1    Thread 0x7f4d64a7d9c0 (LWP 30) "bgpd"        0x00007f4d6471b2d6 in __ppoll (fds=0x7f4d6413b010, nfds=nfds@entry=12, timeout=<optimized out>, sigmask=sigmask@entry=0x7fff5577b930) at ../sysdeps/unix/sysv/linux/ppoll.c:42
  2    Thread 0x7f4d63a006c0 (LWP 31) "RCU sweeper" syscall () at ../sysdeps/unix/sysv/linux/x86_64/syscall.S:38
  3    Thread 0x7f4d630006c0 (LWP 32) "bgpd_io"     0x00007f4d6471b2d6 in __ppoll (fds=0x7f4d63e2b010, nfds=nfds@entry=4, timeout=<optimized out>, sigmask=sigmask@entry=0x7f4d62fffa60) at ../sysdeps/unix/sysv/linux/ppoll.c:42
  4    Thread 0x7f4d626006c0 (LWP 33) "bgpd_ka"     __futex_abstimed_wait_common64 (private=0, cancel=true, abstime=0x7f4d625ffb80, op=137, expected=0, futex_word=0x7f4d54000bc8) at ./nptl/futex-internal.c:57

```

Here, we can attach to the function we want to debug and use `continue` as many times as needed to let the code execute.
```
(gdb) b vpn_leak_to_vrf_update_onevrf
Breakpoint 1 at 0x56441d1c3200: file ../bgpd/bgp_mplsvpn.c, line 2063.
(gdb) continue
```

