# Upstream arm64 YugabyteDB image (python tooling, yugabyted, UI, entrypoint) with the master/tserver/postgres/libs
# swapped for our armv8-a+crc (Cortex-A72 / Pi 4) build. The build tree and its rebuilt thirdparty libs sit at the
# absolute paths they were built at (RPATHs point there); see ../.github/workflows/image.yml.
ARG BASE=yugabytedb/yugabyte:2024.2.7.3-b1
FROM ${BASE}
COPY ctx/ /
# upstream's yb-server is the armv8.2 build; make every entry point resolve to ours
ARG B=/__w/yugabyte-pi/yugabyte-pi/yb/build/release-clang17-dynamic-ninja
RUN rm -f /home/yugabyte/bin/yb-server \
 && ln -sf $B/bin/yb-master /home/yugabyte/bin/yb-master && ln -sf $B/bin/yb-tserver /home/yugabyte/bin/yb-tserver \
 && for f in $B/bin/*; do n=$(basename "$f"); [ -e "/home/yugabyte/bin/$n" ] && ln -sf "$f" "/home/yugabyte/bin/$n"; done; true
# one tree only: point upstream's armv8.2 lib/postgres dirs at ours, and overwrite its thirdparty libs with the rebuilt ones
RUN set -e; Y=/home/yugabyte; TP=/opt/yb-build/thirdparty/tp/installed; \
    rm -rf $Y/lib/yb $Y/postgres $Y/lib/postgres; \
    ln -s $B/lib $Y/lib/yb; ln -s $B/postgres $Y/postgres; ln -s $B/postgres/lib $Y/lib/postgres; \
    cp -a $TP/uninstrumented/lib/*.so* $TP/uninstrumented/libcxx/lib/*.so* $TP/common/lib/*.so* $Y/lib/yb-thirdparty/; \
    if [ -x $TP/common/bin/redis-cli ]; then cp -f $TP/common/bin/redis-cli $Y/bin/redis-cli; fi
