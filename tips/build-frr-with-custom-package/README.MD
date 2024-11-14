# Use custom binaries for FRR and use it on Containerlab

First, we will build our FRR binaries from the sources.

Since my Docker image is based on Bookworm, I used a Bookworm environment to build, following this documentation: https://docs.frrouting.org/projects/dev-guide/en/latest/building-frr-for-debian12.html.

I have installed the necessary packages.
```bash
sudo apt-get install git autoconf automake libtool make \
   libprotobuf-c-dev protobuf-c-compiler build-essential \
   python3-dev python3-pytest python3-sphinx libjson-c-dev \
   libelf-dev libreadline-dev cmake libcap-dev bison flex \
   pkg-config texinfo gdb libgrpc-dev python3-grpc-tools
```

retrieved and compiled libyang.
```bash
git clone https://github.com/CESNET/libyang.git
cd libyang
git checkout v2.1.128
mkdir build; cd build
cmake --install-prefix /usr \
      -D CMAKE_BUILD_TYPE:String="Release" ..
make
```

Now we can retrieve the FRR sources, make our modifications, and compile them.

However, before compiling, we want to change the optimization parameter in the compilation to facilitate future debugging. 
We find this parameter in the project's Makefile.
```bash
git clone https://github.com/frrouting/frr.git frr
cd frr
```

```Makefile
CFLAGS =  -g -O0
```

```
./bootstrap.sh
./configure \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --sbindir=/usr/lib/frr \
    --enable-multipath=64 \
    --enable-user=frr \
    --enable-group=frr \
    --enable-vty-group=frrvty \
    --enable-configfile-mask=0640 \
    --enable-logfile-mask=0640 \
    --enable-fpm \
    --with-pkg-git-version \
    --with-pkg-extra-version=-MyOwnFRRVersion
make
```

Now we can retrieve our binaries and the necessary libraries. 
To simplify the operations, here is a simple script.
```bash
#!/bin/bash
MY_REMOTE_BUILDER=toto.fr

rsync -av ${MY_REMOTE_BUILDER}:~/libyang/build/libyang.so.2.41.0 libyang.so.2
rsync -av ${MY_REMOTE_BUILDER}:/lib/x86_64-linux-gnu/libjson-c.so.5.2.0  libjson-c.so.5

rsync -av ${MY_REMOTE_BUILDER}:~/frr/mgmtd/.libs/libmgmt_be_nb.so.0.0.0  libmgmt_be_nb.so.0


rsync -av ${MY_REMOTE_BUILDER}:~/frr/bgpd/.libs/bgpd .
rsync -av ${MY_REMOTE_BUILDER}:~/frr/vtysh/.libs/vtysh .
rsync -av ${MY_REMOTE_BUILDER}:~/frr/lib/.libs/libfrr.so.0.0.0 libfrr.so.0
rsync -av ${MY_REMOTE_BUILDER}:~/frr/zebra/.libs/zebra .
rsync -av ${MY_REMOTE_BUILDER}:~/frr/watchfrr/.libs/watchfrr .
rsync -av ${MY_REMOTE_BUILDER}:~/frr/mgmtd/.libs/mgmtd .


rsync -av ${MY_REMOTE_BUILDER}:~/frr/ frr-sources
```

Here we can modify our Dockerfile to copy the binaries.
```
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
```

Our image is now ready for debugging our development binaries.
