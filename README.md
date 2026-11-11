# yugabyte-pi

[YugabyteDB](https://github.com/yugabyte/yugabyte-db) for the Raspberry Pi 4 (Cortex-A72, ARMv8.0-A).

The official arm64 release builds are compiled with
`-march=armv8.2-a+fp16+rcpc+dotprod+crypto -mtune=neoverse-n1`, so `yb-master` / `yb-tserver`
die with `SIGILL` on a Pi 4 ([yugabyte-db#26820](https://github.com/yugabyte/yugabyte-db/issues/26820)).
The prebuilt thirdparty libraries (libc++, abseil, tcmalloc, ...) have the same problem.

## Image

```
docker pull ghcr.io/jrcichra/yugabyte-pi:2025.2.8.1-b1
```

Run it like upstream's image:

```
docker run -d -p 5433:5433 -p 7000:7000 -p 9000:9000 ghcr.io/jrcichra/yugabyte-pi:2025.2.8.1-b1 \
  bin/yugabyted start --background=false
```

Tags: `<version>-bN` is an immutable build, so pin it. `<version>` floats to the newest build.

| Version | Postgres | Notes |
|---|---|---|
| `2025.2.8.1` (current, LTS) | 15 | `-b1` is good on a Pi. It includes the tcmalloc 39-bit fix. |
| `2024.2.7.3` (old) | 11 | **`-b1` is broken on real Pi 4s**: its tcmalloc assumed a 48-bit address space (Pi kernels have 39) and `yb-master` / `yb-tserver` died at random on start. Fixed in `-b2`. Use `-b2` or later. |

The 2025.x build differs from 2024.x:

- `pg_parquet` is skipped (it needs a Rust toolchain the build container lacks); the Pi image doesn't use it.
- The ASH collector bgworker segfaults under qemu-user but runs fine on native arm64 (checked on a Neoverse N1 runner),
  so the QEMU smoke test starts the tserver with ASH off and a `verify` job re-tests the published tag natively with ASH
  on. ASH is on by default as upstream; it costs a 64 MB buffer, so you may still want `ysql_yb_enable_ash=false` on a Pi.
- Upgrading a 2024.x (PG11) universe to 2025.x needs YSQL's major catalog upgrade, not just a new image. A fresh
  universe needs nothing special.

Each tag is one multi-platform image: `linux/amd64` is upstream's stock `yugabytedb/yugabyte:<version>-bN`, untouched;
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

## Releasing

Actions → release → Run workflow. Bump `tag` to the next `-bN` (a published tag is never overwritten; the `check` job
refuses it, and refuses inputs for mismatched versions) and set `yb_tag`, `base` and `thirdparty_commit` for a new
Yugabyte version. A full build is about 40 minutes with a warm ccache. Untick `publish` for a dry run that still
runs both smoke tests. `lint` runs shellcheck on `scripts/`.

Not affiliated with Yugabyte, Inc. YugabyteDB is Apache-2.0 licensed (some features are under a separate
license); "YugabyteDB" is their trademark.
