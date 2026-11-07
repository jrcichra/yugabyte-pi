# yugabyte-pi

Working out how to run [YugabyteDB](https://github.com/yugabyte/yugabyte-db) on
a Raspberry Pi 4 (Cortex-A72, ARMv8.0-A).

The official arm64 release builds are compiled with
`-march=armv8.2-a+fp16+rcpc+dotprod+crypto -mtune=neoverse-n1`
(`CMakeLists.txt`, `if(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")`), so
`yb-master` / `yb-tserver` die with `SIGILL` on a Pi 4
([yugabyte-db#26820](https://github.com/yugabyte/yugabyte-db/issues/26820)).

Everything here runs on GitHub-hosted runners, nothing needs a Pi:

- **`repro`** runs the official arm64 image's `yb-master` under QEMU's
  `cortex-a72` model (a faithful ARMv8.0 CPU: unsupported instructions raise
  SIGILL) with `neoverse-n1` as a control, then scans the binaries for
  instructions a Pi 4 lacks and maps them to symbols.

Not affiliated with Yugabyte, Inc. YugabyteDB is Apache-2.0 licensed
(some features are under a separate license); "YugabyteDB" is their trademark.
