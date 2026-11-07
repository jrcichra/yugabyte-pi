#!/usr/bin/env bash
# Count instructions a Cortex-A72 (ARMv8.0 + CRC, no crypto) cannot execute,
# per class, with the symbols that contain the most of them.
# usage: scan.sh <aarch64 ELF>
set -euo pipefail
bin=$1
aarch64-linux-gnu-objdump -d --no-show-raw-insn "$bin" | awk '
  /^[0-9a-f]+ <.*>:$/ { sym=$2; gsub(/[<>:]/,"",sym); next }
  {
    # mnemonic is field 2 after "addr:" (objdump -d prints "  addr:\tmnemonic\toperands")
    m=$2
    c=""
    if (m ~ /^(ldadd|ldclr|ldeor|ldset|ldsmax|ldsmin|ldumax|ldumin|swp|cas|casp)(a|l|al)?(b|h)?$/) c="LSE atomics (v8.1)"
    else if (m ~ /^ldapr/ || m ~ /^ldapur/ || m ~ /^stlur/) c="RCpc (v8.3/8.4)"
    else if (m ~ /^(sdot|udot)$/) c="dotprod (v8.2)"
    else if (m ~ /^(aese|aesd|aesmc|aesimc|sha1[a-z0-9]*|sha256[a-z0-9]*|sha512[a-z0-9]*|pmull2?)$/) c="crypto ext"
    else if (m ~ /^(sqrdmlah|sqrdmlsh)$/) c="RDM (v8.1)"
    else if ($0 ~ /\<(fadd|fsub|fmul|fdiv|fcvt|fmla|fmov)\>[^\n]*\<h[0-9]+\>/) c="fp16 (v8.2)"
    if (c != "") { n[c]++; s[c SUBSEP sym]++ }
  }
  END {
    for (c in n) {
      printf "\n== %s: %d instructions\n", c, n[c]
      for (k in s) { split(k, p, SUBSEP); if (p[1]==c) printf "%8d  %s\n", s[k], p[2] | "sort -rn | head -12" }
      close("sort -rn | head -12")
    }
  }'
