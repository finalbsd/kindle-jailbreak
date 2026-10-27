#!/bin/sh
# 下载越狱要用的文件到 ./files，并逐个核对 SHA256。
# 只下载、只核对，不碰 Kindle，也不执行下载的任何文件。
# 用法：sh fetch-files.sh
set -eu

cd "$(dirname "$0")"
mkdir -p files
cd files

S3=https://s3.amazonaws.com/G7G_FirmwareUpdates_WebDownloads
MR=https://storage.gra.cloud.ovh.net/v1/AUTH_2ac4bfee353948ec8ea7fd1710574097/mr-public/KUAL

get() {  # get <文件名> <网址>
    if [ -f "$1" ]; then echo "已有 $1，跳过下载"; return; fi
    echo "下载 $1"
    curl -fL --progress-bar -o "$1" "$2"
}

get update_kindle_5.4.4.2.bin   "$S3/update_kindle_5.4.4.2.bin"
get update_kindle_5.6.1.1.bin   "$S3/update_kindle_5.6.1.1.bin"
# 越狱包在 KindleModding 仓库里用 Git LFS 存，要走 media 地址，直接下 raw 只会得到一个几十字节的占位文件
get kindle-5.4-jailbreak.zip    "https://media.githubusercontent.com/media/KindleModding/kindlemodding.github.io/main/content/jailbreaking/Legacy/K5-Jailbreak/kindle-5.4-jailbreak.zip"
get Update_hotfix_universal.bin "https://github.com/KindleModding/Hotfix/releases/latest/download/Update_hotfix_universal.bin"
get koreader-kindle-v2026.07.1.zip "https://github.com/koreader/koreader/releases/download/v2026.07.1/koreader-kindle-v2026.07.1.zip"
get KUAL-v2.7.37-gfcb45b5-20250419.tar.xz "$MR/KUAL-v2.7.37-gfcb45b5-20250419.tar.xz"

echo "---- 核对 SHA256 ----"
if shasum -a 256 -c ../SHA256SUMS.txt; then
    echo "全部一致。"
else
    echo "有文件对不上。先别拷进 Kindle。" >&2
    echo "热修复包用的是 latest 地址，作者发新版后哈希会变；其他文件对不上说明下载损坏或被替换。" >&2
    exit 1
fi

# 从 KUAL 压缩包里取出要放进 documents/ 的那一个文件
if [ ! -f KUAL-KDK-2.0.azw2 ]; then
    mkdir -p kual-x
    tar -xf KUAL-v2.7.37-gfcb45b5-20250419.tar.xz -C kual-x
    cp kual-x/KUAL-KDK-2.0.azw2 .
fi
echo "KUAL-KDK-2.0.azw2 sha256: $(shasum -a 256 KUAL-KDK-2.0.azw2 | cut -d' ' -f1)"
echo "（应为 1d7cf02741be9e8f9c541af4eb5e1a97c00ab158819236749dba9250ad1fd4a9）"
