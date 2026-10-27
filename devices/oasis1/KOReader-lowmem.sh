#!/bin/sh
# Name: KOReader（省内存）
# Author: local
# DontUseFBInk

# 启动 KOReader 前停掉 Kindle 原系统（framework），退出 KOReader 时自动恢复。
# 2026-10-26：KOReader 崩溃退出（crash.log 新增报错）时自动重新打开，10 分钟内最多 3 次；正常退出不重开。
LOG=/mnt/us/koreader/crash.log
WLOG=/mnt/us/koreader/lowmem-wrapper.log
tries=0
window_start=$(date +%s)
while :; do
    before=$(wc -c < "$LOG" 2>/dev/null || echo 0)
    /var/local/kmc/bin/kpm launch koreader --framework_stop
    rc=$?
    after=$(wc -c < "$LOG" 2>/dev/null || echo 0)
    crashed=0
    if [ "$after" -gt "$before" ] && tail -c $((after - before)) "$LOG" | grep -q -E '^\./luajit: |stack traceback'; then
        crashed=1
    fi
    echo "$(date '+%F %T') exit rc=$rc crashed=$crashed" >> "$WLOG"
    [ "$crashed" -eq 1 ] || break
    now=$(date +%s)
    if [ $((now - window_start)) -gt 600 ]; then tries=0; window_start=$now; fi
    tries=$((tries + 1))
    if [ "$tries" -gt 3 ]; then echo "$(date '+%F %T') give up after 3 restarts" >> "$WLOG"; break; fi
    sleep 8
done
