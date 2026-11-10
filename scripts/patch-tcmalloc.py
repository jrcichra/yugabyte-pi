#!/usr/bin/env python3
"""Patch yugabyte-db-thirdparty's tcmalloc build (run from the thirdparty checkout root).
Google tcmalloc hardcodes kAddressBits = 48 on aarch64, but Raspberry Pi OS kernels use 39-bit user
virtual addresses, so its mmap hints (up to 2^48) fail and every yb-master/yb-tserver start dies with
"MmapAligned() failed ... TCMALLOC_ADDRESS_BITS" at random. This yugabyte/tcmalloc fork has no such
macro, so rewrite the constant before bazel runs. 39 is valid on every kernel (48-bit ones just never
use the upper range)."""
p = "python/build_definitions/tcmalloc.py"
s = open(p).read()
old = "        self.update_workspace_file()\n"
new = old + (
    "        cfg = os.path.join(os.getcwd(), 'tcmalloc', 'internal', 'config.h')\n"
    "        src = open(cfg).read()\n"
    "        marker = 'defined __aarch64__ && defined __linux__'\n"
    "        head, sep, tail = src.partition(marker)\n"
    "        assert sep and tail.count('inline constexpr int kAddressBits = 48;') >= 1, 'tcmalloc config.h changed'\n"
    "        tail = tail.replace('inline constexpr int kAddressBits = 48;', 'inline constexpr int kAddressBits = 39;', 1)\n"
    "        open(cfg, 'w').write(head + sep + tail)\n"
    "        log('tcmalloc: aarch64 kAddressBits 48 -> 39')\n"
)
assert s.count(old) == 1, "tcmalloc.py build() changed"
open(p, "w").write(s.replace(old, new))
