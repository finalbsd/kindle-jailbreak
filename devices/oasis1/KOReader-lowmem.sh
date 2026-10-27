#!/bin/sh
# Name: KOReader（省内存）
# Author: local
# DontUseFBInk

# 启动 KOReader 前停掉 Kindle 原系统（framework），退出 KOReader 时自动恢复。
/var/local/kmc/bin/kpm launch koreader --framework_stop
