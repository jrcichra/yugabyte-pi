# linux/amd64: upstream's stock image, untouched.
# linux/arm64: upstream's image with master/tserver/postgres/tools/libs swapped for our ARMv8.0 (Cortex-A72 / Pi 4)
# build. The build tree and its rebuilt thirdparty libs sit at the absolute paths they were built at (RPATHs point there).
ARG BASE=yugabytedb/yugabyte:2024.2.7.3-b1
ARG TARGETARCH
FROM ${BASE} AS stock

FROM stock AS final-amd64

FROM stock AS final-arm64
ARG B
COPY ctx/ /
# one tree only: no armv8.2 binaries or libs left reachable from /home/yugabyte
RUN set -e; Y=/home/yugabyte; TP=/opt/yb-build/thirdparty/tp/installed; \
    rm -f $Y/bin/yb-server; rm -rf $Y/lib/yb $Y/postgres $Y/lib/postgres; \
    ln -s $B/lib $Y/lib/yb; ln -s $B/postgres $Y/postgres; ln -s $B/postgres/lib $Y/lib/postgres; \
    ln -sf $B/bin/yb-master $Y/bin/yb-master; ln -sf $B/bin/yb-tserver $Y/bin/yb-tserver; \
    for f in $B/bin/*; do n=$(basename "$f"); if [ -e "$Y/bin/$n" ]; then ln -sf "$f" "$Y/bin/$n"; fi; done; \
    cp -a $TP/uninstrumented/lib/*.so* $TP/uninstrumented/libcxx/lib/*.so* $TP/common/lib/*.so* $Y/lib/yb-thirdparty/; \
    cp -f $TP/common/bin/redis-cli $Y/bin/redis-cli

FROM final-${TARGETARCH}
LABEL org.opencontainers.image.source="https://github.com/jrcichra/yugabyte-pi" \
      org.opencontainers.image.description="YugabyteDB: stock on amd64, ARMv8.0 (Raspberry Pi 4) build on arm64" \
      org.opencontainers.image.licenses="Apache-2.0"
