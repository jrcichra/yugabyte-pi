#!/usr/bin/env bash
# Run every executable in the image's /home/yugabyte/{bin,postgres/bin} with --version under QEMU as a Cortex-A72
# and fail on any illegal instruction (SIGILL).  usage: tools-smoke.sh <rootfs dir>
R=$(realpath "$1")
for m in proc dev sys; do mountpoint -q "$R/$m" || sudo mount --bind "/$m" "$R/$m"; done
bad=0; n=0
for f in $(cd "$R" && find home/yugabyte/bin home/yugabyte/postgres/bin -maxdepth 1 \( -type f -o -type l \)); do
  sudo chroot "$R" /bin/sh -c "file_ok=\$(head -c4 /$f 2>/dev/null | od -An -c | tr -d ' '); [ \"\$file_ok\" = '177ELF' ]" 2>/dev/null || continue
  n=$((n+1))
  out=$(sudo env QEMU_CPU=cortex-a72 HOME=/tmp timeout 60 chroot --userspec=10001:10001 "$R" "/$f" --version </dev/null 2>&1 | head -c 600)
  if echo "$out" | grep -q -E "uncaught target signal 4|Illegal instruction"; then echo "SIGILL  /$f"; bad=$((bad+1)); else echo "ok      /$f"; fi
done
echo "tools checked: $n, SIGILL: $bad"
[ "$bad" = 0 ] && [ "$n" -gt 0 ]
