#!/usr/bin/env bash
# Print "<count> <path>" for aarch64 ELF files under the given dirs that contain instructions a Cortex-A72 (Pi 4) lacks:
# LSE atomics, RCpc loads, dot-product. Skips the compiler's __aarch64_* outline-atomic helpers, which choose
# LSE vs LL/SC at runtime and are harmless.   usage: scan-offenders.sh <dir>...
find "$@" -type f \( -name '*.so*' -o -perm -u+x \) 2>/dev/null | while read -r f; do
  file -b "$f" | grep -q 'ELF 64-bit.*ARM aarch64' || continue
  n=$(aarch64-linux-gnu-objdump -d --no-show-raw-insn "$f" 2>/dev/null | awk '
    /^[0-9a-f]+ <.*>:$/ { skip = ($2 ~ /^<__aarch64_/); next }
    !skip && $2 ~ /^(ldadd|ldclr|ldeor|ldset|swp|casp?|ldapr|ldapur|sdot|udot)[a-z]*$/ { c++ }
    END { print c+0 }')
  [ "$n" -gt 0 ] && echo "$n $f"
done | sort -rn
