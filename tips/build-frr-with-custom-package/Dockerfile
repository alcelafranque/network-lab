FROM debian:bookworm

ENV DEBIAN_FRONTEND noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

RUN apt-get update && \
    apt-get install -y libpcre3-dev apt-transport-https ca-certificates curl wget logrotate \
    libc-ares2 libjson-c5 vim procps libreadline8 gnupg2 lsb-release apt-utils \
    libprotobuf-c-dev protobuf-c-compiler tini && rm -rf /var/lib/apt/lists/*

# Install frr to have somes tools and libs
RUN apt-get update && \
    apt-get install -y frr frr-pythontools gdb && \
    rm -rf /var/lib/apt/lists/*

# Add my custom configuration for frr daemons
ADD frrcommon.sh /usr/lib/frr/frrcommon.sh

# Add my custom bimaries
ADD bgpd /usr/lib/frr/bgpd
ADD vtysh /usr/bin/vtysh
ADD zebra /usr/lib/frr/zebra
ADD mgmtd /usr/lib/frr/mgmtd
ADD watchfrr /usr/lib/frr/watchfrr
ADD libyang.so.2 /lib/x86_64-linux-gnu/libyang.so.2
ADD libfrr.so.0 /usr/lib/x86_64-linux-gnu/frr/libfrr.so.0
ADD libmgmt_be_nb.so.0 /usr/lib/x86_64-linux-gnu/frr/libmgmt_be_nb.so.0

# Add LD path and sources (to help gdb)
ADD ld.frr.conf /etc/ld.so.conf.d/frr.conf
ADD frr-sources /root/frr-sources

RUN ldconfig

# Own the config / PID files
RUN mkdir -p /var/run/frr
RUN chown -R frr:frr /etc/frr /var/run/frr

# Simple init manager for reaping processes and forwarding signals
ENTRYPOINT ["/usr/bin/tini", "--"]

# Default CMD starts watchfrr
COPY --chmod=0755 docker-start /usr/lib/frr/docker-start
CMD ["/usr/lib/frr/docker-start"]

