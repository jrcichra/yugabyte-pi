# yugabyte-pi

[YugabyteDB](https://github.com/yugabyte/yugabyte-db) for the Raspberry Pi 4 (and anything newer).

The official arm64 release builds are compiled with
`-march=armv8.2-a+fp16+rcpc+dotprod+crypto -mtune=neoverse-n1`, so `yb-master` / `yb-tserver`
die with `SIGILL` on a Pi 4 ([yugabyte-db#26820](https://github.com/yugabyte/yugabyte-db/issues/26820)).
This repo rebuilds YugabyteDB and its thirdparty libraries for plain ARMv8.0-A (the Pi 4's Cortex-A72 is the baseline),
so one image runs on any Pi. A Pi 5 (Cortex-A76, ARMv8.2) can also run upstream's stock image.

## Image

```
docker pull ghcr.io/jrcichra/yugabyte-pi:2025.2.8.1-b2
```

Run it like upstream's image:

```
docker run -d -p 5433:5433 -p 7000:7000 -p 9000:9000 ghcr.io/jrcichra/yugabyte-pi:2025.2.8.1-b2 \
  bin/yugabyted start --background=false
```

Tags: `<version>-bN` is an immutable build, so pin it. `<version>` floats to the newest build.

Each tag is one multi-platform image: `linux/amd64` is upstream's stock `yugabytedb/yugabyte:<version>-bN`, untouched;
`linux/arm64` is that image with the server, tools, Postgres and thirdparty libs rebuilt for ARMv8.0, and the same
set of Postgres extensions. Needs a 64-bit OS on the Pi.

Tested on a Pi 4 (under QEMU in CI) and on a real Pi 5 (16K-page kernel): master + tserver + YSQL, `pg_parquet`
and ASH on, for both this image and upstream's.

## Pipeline

`.github/workflows/release.yml` (manual dispatch, runs on GitHub-hosted runners):

1. **check**: the inputs agree with each other, and the tag isn't already published.
2. **thirdparty**: rebuild [yugabyte-db-thirdparty](https://github.com/yugabyte/yugabyte-db-thirdparty) with `-march=armv8-a+crc`.
3. **build**: rebuild `yb-master`, `yb-tserver`, Postgres and the tools against it.
4. **image**: overlay onto upstream's arm64 image, then test it as a Cortex-A72 (the Pi 4 core, the oldest target) under QEMU,
   which raises `SIGILL` on any instruction it lacks: the extension set matches upstream's, every executable runs, and a master +
   tserver + YSQL session does create/insert/select. Only then is the image published.
5. **verify**: `smoke.yml` runs the published tag natively on arm64 with stock flags.

`scripts/`: `curl-gh` and `patch-downloader.py` work around GitHub's flaky release downloads and unstable
`/archive/` tarballs in the thirdparty build, `patch-tcmalloc.py` sets tcmalloc's address width to 39 bits (Pi kernels
use 39-bit user addresses), and `tools-smoke.sh` and `ysql-smoke.sh` are the tests. `smoke.yml` can also be run by hand
against any published image.

## Releasing

Actions → release → Run workflow. Bump `tag` to the next `-bN` (a published tag is never overwritten) and set `yb_tag`,
`base` and `thirdparty_commit` for a new Yugabyte version. A full build takes under an hour. Untick `publish` for a dry
run that still runs both smoke tests.

Not affiliated with Yugabyte, Inc. YugabyteDB is Apache-2.0 licensed (some features are under a separate
license); "YugabyteDB" is their trademark.
