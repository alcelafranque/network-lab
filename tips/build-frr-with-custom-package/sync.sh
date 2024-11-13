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
