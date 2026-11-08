# Upstream arm64 YugabyteDB image (python tooling, yugabyted, UI, entrypoint) with the master/tserver/postgres/libs
# swapped for our armv8-a+crc (Cortex-A72 / Pi 4) build. The build tree and its rebuilt thirdparty libs sit at the
# absolute paths they were built at (RPATHs point there); see ../.github/workflows/image.yml.
ARG BASE=yugabytedb/yugabyte:2024.2.7.3-b1
FROM ${BASE}
COPY ctx/ /
# upstream's yb-server is the armv8.2 build; make every entry point resolve to ours
RUN rm -f /home/yugabyte/bin/yb-master /home/yugabyte/bin/yb-tserver /home/yugabyte/bin/yb-server \
 && ln -s /__w/yugabyte-pi/yugabyte-pi/yb/build/release-clang17-dynamic-ninja/bin/yb-master  /home/yugabyte/bin/yb-master \
 && ln -s /__w/yugabyte-pi/yugabyte-pi/yb/build/release-clang17-dynamic-ninja/bin/yb-tserver /home/yugabyte/bin/yb-tserver
