#!/bin/sh
# 一键体检：通过 KOReader 的 SSH（端口 2222）只读查看 Kindle 状态，不改任何东西。
# 用法：sh tools/kindle-health.sh <Kindle 的 IP>
set -eu
IP="${1:?用法：sh tools/kindle-health.sh <Kindle 的 IP>}"

ssh -o ConnectTimeout=10 -p 2222 "root@$IP" 'sh -s' <<'REMOTE'
echo "== 固件"
head -1 /mnt/us/system/version.txt 2>/dev/null || echo "读不到 version.txt"

echo "== 开机时长和负载"
uptime

echo "== 电量"
echo "电量 $(lipc-get-prop com.lab126.powerd battLevel 2>/dev/null || echo ?)%，$(lipc-get-prop com.lab126.powerd isCharging 2>/dev/null | sed 's/1/充电中/;s/0/没充电/')"

echo "== 存储（/mnt/us 是 USB 能看到的那块盘；/ 是系统盘，不要往里写）"
df -h /mnt/us / | sed 1d

echo "== 内存（看 -/+ buffers/cache 那一行的 free）"
free -m

echo "== 谁在运行"
pidof reader.lua >/dev/null && echo "KOReader：在运行" || echo "KOReader：没运行"
pidof cvm >/dev/null && echo "Kindle 原系统（cvm）：在运行" || echo "Kindle 原系统（cvm）：已停（省内存启动时正常）"

echo "== 自动升级"
if [ -d /mnt/us/update.bin.tmp.partial ]; then echo "已用 update.bin.tmp.partial 文件夹屏蔽"; else echo "根目录没有 update.bin.tmp.partial 文件夹"; fi
ls /mnt/us/*.bin /mnt/us/update*.bin 2>/dev/null | sed 's/^/根目录有待装的固件：/' || true

echo "== 触摸芯片 5 秒内的中断数（手别碰屏幕，应为 0）"
line=$(grep -iE 'ttsp|zforce|touch' /proc/interrupts | head -1)
if [ -n "$line" ]; then
  name=$(echo "$line" | awk '{print $NF}')
  a=$(echo "$line" | awk '{print $2}')
  sleep 5
  b=$(grep "$name" /proc/interrupts | head -1 | awk '{print $2}')
  echo "$name：$((b - a))"
else
  echo "没找到触摸芯片的中断行"
fi

echo "== 最近的内存不足（OOM）记录"
dmesg 2>/dev/null | grep -i "out of memory" | tail -3 || true

echo "== KOReader 日志里最近的错误"
grep -E "ERROR|stack traceback" /mnt/us/koreader/crash.log 2>/dev/null | tail -5 || true
REMOTE
