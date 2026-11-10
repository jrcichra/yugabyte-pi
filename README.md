# yugabyte-pi

[YugabyteDB](https://github.com/yugabyte/yugabyte-db) for the Raspberry Pi 4 (Cortex-A72, ARMv8.0-A).

The official arm64 release builds are compiled with
`-march=armv8.2-a+fp16+rcpc+dotprod+crypto -mtune=neoverse-n1`, so `yb-master` / `yb-tserver`
die with `SIGILL` on a Pi 4 ([yugabyte-db#26820](https://github.com/yugabyte/yugabyte-db/issues/26820)).
The prebuilt thirdparty libraries (libc++, abseil, tcmalloc, ...) have the same problem.

## Image

```
docker pull ghcr.io/jrcichra/yugabyte-pi:2024.2.7.3-b2
```

Tags: `2024.2.7.3-bN` is an immutable build, so pin it. `2024.2.7.3` floats to the newest build.
`-b1` is broken on real Pi 4s: its tcmalloc assumed a 48-bit address space and `yb-master` / `yb-tserver`
died at random on start (fixed in `-b2`, which patches `kAddressBits` to 39). Use `-b2` or later on a Pi.

Each tag is one multi-platform image: `linux/amd64` is upstream's stock `yugabytedb/yugabyte:2024.2.7.3-b1`, untouched;
`linux/arm64` is that image with the server, tools, Postgres and thirdparty libs rebuilt for ARMv8.0.
Needs a 64-bit OS on the Pi.

## Pipeline

One workflow, `.github/workflows/release.yml` (manual dispatch, runs entirely on GitHub-hosted runners):

1. **thirdparty**: rebuild [yugabyte-db-thirdparty](https://github.com/yugabyte/yugabyte-db-thirdparty) with `-march=armv8-a+crc`.
2. **build**: rebuild `yb-master`, `yb-tserver`, Postgres and the tools against it.
3. **image**: overlay onto upstream's arm64 image, then test it as a Cortex-A72 under QEMU (which raises `SIGILL`
   on any instruction a Pi 4 lacks): every executable runs, and a master + tserver + YSQL session does
   create/insert/select. Only then is the image published.

`scripts/`: `curl-gh` and `patch-downloader.py` work around GitHub's flaky release downloads and unstable
`/archive/` tarballs in the thirdparty build; `tools-smoke.sh` and `ysql-smoke.sh` are the tests.

Not affiliated with Yugabyte, Inc. YugabyteDB is Apache-2.0 licensed (some features are under a separate
license); "YugabyteDB" is their trademark.
