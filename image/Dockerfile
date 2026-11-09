# arm64 only (amd64 is upstream's stock image, merged in by the workflow). Overlays our ARMv8.0 (Cortex-A72 / Pi 4) build
# onto upstream's image; the workflow then `crane flatten`s it so the superseded armv8.2 files don't ship.
ARG BASE=yugabytedb/yugabyte:2024.2.7.3-b1
FROM ${BASE}
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
LABEL org.opencontainers.image.source="https://github.com/jrcichra/yugabyte-pi" \
      org.opencontainers.image.description="YugabyteDB: stock on amd64, ARMv8.0 (Raspberry Pi 4) build on arm64" \
      org.opencontainers.image.licenses="Apache-2.0"
