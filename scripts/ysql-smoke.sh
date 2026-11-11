#!/usr/bin/env bash
# Boot master + tserver(+YSQL) from the build tree under QEMU as a Cortex-A72 (Pi 4) in a chroot of the
# upstream arm64 rootfs, then run SQL. usage: ysql-smoke.sh <rootfs dir> <absolute build dir inside it>
set -u
R=$(realpath "$1"); B=$2
sudo mount --bind /proc "$R/proc"; sudo mount --bind /dev "$R/dev"; sudo mount --bind /sys "$R/sys"
sudo mount -t tmpfs -o mode=1777 tmpfs "$R/dev/shm"   # YSQL backends create shared-memory exchanges here (a plain --bind /dev leaves it root-only)
sudo chmod -R a+rX "$R/__w" "$R/opt/yb-build" 2>/dev/null   # CI build files are root-only; the image build must do the same
sudo mkdir -p "$R/tmp/m" "$R/tmp/t"; sudo chown -R 10001:10001 "$R/tmp"
# shellcheck disable=SC2012
ls /proc/sys/fs/binfmt_misc/ | head   # shows qemu is registered
run() { sudo env QEMU_CPU=cortex-a72 HOME=/tmp chroot --userspec=10001:10001 "$R" "$@"; }

run "$B/bin/yb-master" --master_addresses=127.0.0.1:7100 --rpc_bind_addresses=127.0.0.1:7100 \
  --fs_data_dirs=/tmp/m --replication_factor=1 --use_private_ip=never --logtostderr > master.log 2>&1 &
sleep 60
run "$B/bin/yb-tserver" --tserver_master_addrs=127.0.0.1:7100 --rpc_bind_addresses=127.0.0.1:9100 \
  --fs_data_dirs=/tmp/t --start_pgsql_proxy --pgsql_proxy_bind_address=127.0.0.1:5433 \
  --ysql_yb_enable_ash=false \
  --use_private_ip=never --logtostderr > tserver.log 2>&1 &   # 2025.x ASH collector bgworker segfaults under qemu-user; also a pointless 64MB buffer on a Pi

ok=0
for i in $(seq 1 90); do   # up to 15 min; QEMU is slow
  sleep 10
  if grep -q -E "Check failed|uncaught target signal" master.log tserver.log 2>/dev/null; then echo "server crashed, giving up"; break; fi
  if out=$(run "$B/postgres/bin/ysqlsh" -h 127.0.0.1 -p 5433 -U yugabyte -v ON_ERROR_STOP=1 \
      -c "select version()" -c "create table t(a int primary key, b text)" \
      -c "insert into t values (1,'pi4'),(2,'ok')" -c "select * from t order by a" 2>&1); then
    echo "$out"; ok=1; break
  fi
  echo "[$i] not yet: $(echo "$out" | tail -1 | cut -c1-160)"
done
echo "ysql_ok=$ok"
sudo pkill -9 -f qemu-aarch64 || true
for f in master.log tserver.log; do
  echo "--- $f: crashes"; grep -n -E "Illegal instruction|terminated by signal|SIGILL|uncaught target signal|Check failed|FATAL" "$f" | head -10
  echo "--- $f tail"; tail -8 "$f" | cut -c1-220
done
[ "$ok" = 1 ]
