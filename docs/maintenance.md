# 日常维护手册

适用：已按本仓库越狱、装了 KOReader 并能用 SSH 连上的 Kindle。命令都在 Oasis 一代和 Paperwhite 一代上用过，个别只在一台上试过的会注明。

## 先认识这台机器

越狱后的 Kindle 就是一台 ARM 小电脑，跑的是精简的 Linux。下面的内容都是从两台设备上实际读出来的。

| | Oasis 一代 | Paperwhite 一代 |
| --- | --- | --- |
| 固件 | 5.16.2.1.1 | 5.6.1.1 |
| 内存 | 498 MB | 250 MB |
| 数据盘 `/mnt/us` | 2.8 GB | 1.3 GB |
| 系统盘 `/` | 437 MB，已用 95% | 348 MB，已用 88% |
| 触摸芯片 | Cypress，中断名 `main_ttsp_core.cyttsp4_i2c_adapter` | Cypress，中断名 `cyttsp` |
| 屏幕 | 1072×1448，每行 1088 字节 | 758×1024，每行 768 字节 |
| KOReader 怎么启动 | KPM 装的，书架里的 `KOReader-lowmem.sh` | KUAL 菜单里的 Start KOReader (no framework) |
| 自动升级程序 `otaupd` | 没在运行（WinterBreak2 已处理） | **还在运行**，见“防止自动升级” |

几个概念：

- **BusyBox**：一个程序顶几十个常用命令（`ls`、`grep`、`tar`……），功能比电脑上的精简。Paperwhite 一代的版本更老，`grep` 和 `sed` 不支持 `-E`，要写成多个 `-e`。`ps` 不显示完整命令行，要看 `/proc/<进程号>/cmdline`。没有 `scp`、`rsync`、`htop`。
- **原系统（framework）**：亚马逊自己的阅读界面，主程序叫 `cvm`（Java 写的，约占 100 MB 内存）。由 upstart 服务 `lab126_gui` 管着。
- **upstart**：开机时按顺序启动各种服务的程序，配置在 `/etc/upstart/`。用 `start`、`stop`、`status`、`initctl list` 操作。
- **lipc**：原系统各个服务之间互相通信的方式。电量、前光、Wi-Fi 都能用 `lipc-get-prop` 读、用 `lipc-set-prop` 改。
- **省内存启动**：KOReader 带 `--framework_stop` 参数启动时，先停掉 `lab126_gui`（`cvm` 跟着退出），退出 KOReader 时再启动它。原系统重新起来要一两分钟。

## 分区和挂载

用 `mount` 能看到全部。要记住的只有这几个：

| 挂载点 | 是什么 | 能不能写 | 重启后 |
| --- | --- | --- | --- |
| `/mnt/us` | 数据盘。USB 连电脑看到的就是它 | 能 | 保留 |
| `/` | 系统盘（ext3） | 平时只读 | 保留 |
| `/var/local` | 系统的数据分区：原系统的数据库、设置、越狱组件 | 能，但别乱动 | 保留 |
| `/var` | 内存盘（tmpfs），Oasis 64 MB、Paperwhite 32 MB | 能 | **清空** |
| `/tmp` | 临时文件 | 能 | **清空** |

`/var/log` 在内存盘里，所以原系统日志重启就没了。要留证据，重启前先拷出来。

`/mnt/us` 其实是一个文件挂上来的（FUSE），USB 模式时它会从 Kindle 这边卸下来交给电脑。所以插着 USB 线、处于“USB 驱动器模式”时，Kindle 上的程序访问不了它，KOReader 也打不开。

## 目录结构

### 数据盘 `/mnt/us`

| 路径 | 内容 | 哪台有 |
| --- | --- | --- |
| `documents/` | 书。每本书旁边的 `书名.sdr/` 文件夹存着 KOReader 的阅读进度、划线、笔记 | 两台 |
| `fonts/` | 自己加的字体。KOReader 会读；新一些的固件，原系统也会读 | 两台 |
| `koreader/` | KOReader 整个程序和它的设置，见下一节 | 两台 |
| `screensaver/` | 自己做的锁屏图（KOReader 用） | 两台 |
| `system/` | 原系统的数据：缩略图（`thumbnails/`）、搜索索引、生词本、固件版本（`version.txt`） | 两台 |
| `libkh/` | 热修复（hotfix）的组件。**别删** | 两台 |
| `mkk/`、`rp/` | K5 越狱的组件。**别删** | Paperwhite |
| `extensions/` | KUAL 的菜单。`extensions/koreader/menu.json` 里写着 KUAL 每一项实际运行的命令 | Paperwhite |
| `developer/KUAL/` | KUAL 程序本身的数据 | Paperwhite |
| `kmc/kpm/` | KPM（Kindle 软件包管理器）的数据库和下载的包 | Oasis |
| `audible/`、`Books/` | 原系统建的空文件夹 | 看机型 |
| `.active_content_sandbox/` | 原系统商店、小程序的缓存 | 两台 |
| `screenshot_*.png`、`wininfo_screenshot_*.txt` | 在原系统里截图留下的。txt 是截图时附带的窗口信息，没用 | 截过图才有 |
| `.Spotlight-V100`、`.fseventsd`、`.Trashes`、`._*` | Mac 生成的，可以删 | 连过 Mac 才有 |

### KOReader 目录 `/mnt/us/koreader`

| 路径 | 内容 |
| --- | --- |
| `koreader.sh` | 启动脚本。KUAL、KPM 最终都是运行它。常用参数 `--framework_stop`（省内存启动） |
| `reader.lua` | 主程序入口 |
| `luajit` | KOReader 自带的 Lua 解释器，不在系统 PATH 里，要写全路径 `./luajit` |
| `settings.reader.lua` | 主设置文件：字体、排版、锁屏、各种开关。`.old` 是上一次的自动备份 |
| `settings/` | 插件和功能的设置，见下表 |
| `history.lua` | 最近读过的书 |
| `crash.log` | 日志。名字叫 crash，平时的记录也写在这里 |
| `defaults.custom.lua` | 改内部默认值用的，一般用不到 |
| `plugins/` | 插件，一个插件一个 `xxx.koplugin` 文件夹 |
| `patches/` | 用户补丁（启动时自动加载的 Lua 文件）。空着最好 |
| `fonts/` | KOReader 自带的字体（界面用）。自己的字体放 `/mnt/us/fonts/` |
| `data/` | 断字表、词典、CSS 等资源 |
| `cache/` | 封面、排版缓存，删了会重新生成 |
| `screenshots/` | 在 KOReader 里截的图 |
| `weread/` | 微信读书插件的数据，`external-annotations/` 里是匹配好的别人的划线 |
| `news/` | 新闻下载插件下的文章 |
| `styletweaks/` | 自定义 CSS 片段 |
| `ota/`、`zsync2`、`spinning_zsync` | KOReader 自己更新用的 |
| `dropbear`、`sftp-server`、`scp`、`dbclient` | SSH 服务器和配套程序（只在 KOReader 里用） |
| `fbink`、`tar`、`wmctrl`、`sdcv` | 自带的小工具：往屏幕写字、打包、窗口管理、查词典 |
| `frontend/`、`common/`、`libs/`、`ffi/`、`jit/` | 程序本体的代码和库，不要改 |
| `l10n/`、`help/`、`icons/`、`resources/` | 翻译、帮助、图标、图片 |
| `version.log`、`git-rev` | 版本号 |

`settings/` 里常见的文件：

| 文件 | 内容 |
| --- | --- |
| `gestures.lua` | 手势设置（点哪个角做什么） |
| `SSH/authorized_keys` | 允许登录的电脑公钥 |
| `weread.lua` | 微信读书插件的登录信息和 API Key。**不要外传** |
| `wereadhl.lua`、`wereadhl/` | 划线同步插件的设置和记录 |
| `simpleui/` | SimpleUI 首页的设置 |
| `statistics.sqlite3` | 阅读统计（读了多久、哪天读的） |
| `bookinfo_cache.sqlite3` | 书的封面、标题缓存。删了会重建 |
| `vocabulary_builder.sqlite3` | 生词本 |
| `collection.lua` | 收藏夹 |
| `battery_stats.lua` | 电量统计 |
| `profiles.lua` | 设置方案 |

### 系统里值得知道的地方

只读看看就好，这些都不要改。

| 路径 | 内容 |
| --- | --- |
| `/etc/upstart/` | 所有开机服务的配置，`lab126_gui.conf`、`framework.conf`、`powerd.conf` 等 |
| `/var/log/messages` | 原系统日志。也可以直接运行 `showlog` 看 |
| `/var/log/Xorg.0.log` | 图形界面的日志 |
| `/var/local/kmc/` | 热修复和 KPM 的程序（`bin/kpm`、`run_hotfix.sh`）。Oasis 上启动 KOReader 用的就是 `/var/local/kmc/bin/kpm` |
| `/var/local/mkk/` | 越狱用的开发者密钥 |
| `/var/local/system/`、`/var/local/*.db` | 原系统的数据库和设置 |
| `/proc/interrupts` | 各个硬件的中断计数，用来查触摸芯片有没有乱报 |
| `/sys/class/power_supply/` | 电池的原始读数（Oasis 上和 `powerd` 的读数会对不上） |
| `/dev/fb0` | 屏幕画面，远程截屏读它 |
| `/dev/input/event*` | 触摸、按键等输入设备。KOReader 运行时独占触摸屏 |

## 核心命令

按“只看不改”和“会改东西”分开。会改东西的，先想清楚再用。

### 只看不改

| 命令 | 用途 |
| --- | --- |
| `cat /mnt/us/system/version.txt` | 固件版本 |
| `uptime` | 开了多久、忙不忙（load average 小于 1 就是不忙） |
| `free -m` | 内存。看 `-/+ buffers/cache` 那一行的 free |
| `df -h /mnt/us /` | 数据盘和系统盘还剩多少 |
| `du -sm /mnt/us/* \| sort -n` | 数据盘里哪个文件夹最大（单位 MB，BusyBox 的 `sort` 不支持 `-h`） |
| `top -b -n1 \| head -15` | 哪个程序在吃 CPU、内存 |
| `ps` | 所有进程。看完整命令行用 `cat /proc/<进程号>/cmdline \| tr '\0' ' '` |
| `pidof reader.lua` | KOReader 在不在运行（有输出就在） |
| `pidof cvm` | 原系统在不在运行 |
| `status lab126_gui` | 原系统服务的状态，`start/running` 是在运行 |
| `initctl list \| grep running` | 所有在运行的服务 |
| `lipc-get-prop com.lab126.powerd battLevel` | 电量（%） |
| `lipc-get-prop com.lab126.powerd isCharging` | 在不在充电（1 是在充） |
| `lipc-get-prop com.lab126.powerd status` | 电源状态，含距离休眠还有多久 |
| `lipc-get-prop com.lab126.powerd flIntensity` | 前光亮度 |
| `lipc-get-prop com.lab126.wifid cmState` | Wi-Fi 状态，`CONNECTED` 是连上了 |
| `lipc-probe -a` | 列出所有能用 lipc 访问的服务 |
| `lipc-probe com.lab126.powerd` | 列出这个服务的所有属性，`r` 只读，`w` 可写 |
| `ifconfig wlan0` | IP 地址 |
| `grep -i ttsp /proc/interrupts` | 触摸芯片的中断计数。隔几秒读两次，手不碰屏幕时应该不变 |
| `dmesg \| tail -30` | 内核日志（硬件、内存不足） |
| `dmesg \| grep -i "out of memory"` | 有没有程序因为内存不足被杀 |
| `showlog \| tail -50` | 原系统日志 |
| `tail -50 /mnt/us/koreader/crash.log` | KOReader 日志 |
| `sqlite3 /mnt/us/koreader/settings/statistics.sqlite3 .tables` | 看 KOReader 的数据库。只读的查询不会改东西 |
| `date` | 系统时间 |

### 会改东西的

| 命令 | 用途 | 注意 |
| --- | --- | --- |
| `lipc-set-prop com.lab126.powerd flIntensity 10` | 设前光亮度 | 数字范围看 `flMaxIntensity` |
| `lipc-set-prop com.lab126.cmd wirelessEnable 0` | 关 Wi-Fi（1 是开） | 关了 SSH 就断了，要在 Kindle 上手动打开 |
| `lipc-set-prop com.lab126.powerd preventScreenSaver 1` | 暂时不让它休眠（0 恢复） | 用完记得改回 0，不然很费电 |
| `killall -TERM reader.lua` | 让 KOReader 退出 | 这本书最近几分钟的划线可能没存 |
| `stop lab126_gui` / `start lab126_gui` | 停、启原系统 | 原系统起来要一两分钟 |
| `eips -c`、`eips 5 5 "文字"` | 清屏、在屏幕上写字 | 只是画上去，下次刷新就没了 |
| `tar -C /mnt/us -cf - koreader/settings` | 打包（配合 SSH 管道备份） | 只读源文件，安全 |
| `reboot` | 重启 Kindle | 等于长按电源键选重启 |

### 不要碰

| 命令 | 为什么 |
| --- | --- |
| `mntroot rw` | 把系统盘改成可写。写坏了可能开不了机 |
| `lipc-set-prop com.lab126.powerd deviceRestart`、`shutdown`、`halt` | 有更安全的 `reboot` 和电源键 |
| `otaupd` 以及 `/etc/upstart/ota*` | 系统升级程序，可能冲掉越狱 |
| `kdb set ...` | 改原系统的内部配置数据库 |
| 往 `/var/local/mkk`、`/var/local/kmc`、`/mnt/us/libkh` 里删改 | 这些是越狱和热修复本身 |
| `rm -rf` 任何你没看清的路径 | 没有回收站 |

## 怎么连上

- **USB**：数据线连电脑，Kindle 显示成一个磁盘。拷书、拷字体、备份都用这个。
- **SSH**：KOReader → 工具 → 更多工具 → SSH 服务器 → 启动，屏幕显示 IP。电脑上：

  ```
  ssh -p 2222 root@<IP>
  ```

  只认公钥，公钥放在 `koreader/settings/SSH/authorized_keys`。设置方法见 [koreader-and-plugins.md](koreader-and-plugins.md)。KOReader 退出时 SSH 也会断。
- Kindle 上没有 `scp`。从 Kindle 取文件用 `ssh ... 'cat 文件' > 本地文件`，或下面备份一节的 `tar` 管道。

## 一键体检

```
sh tools/kindle-health.sh <IP>
```

只读，不改任何东西。会列出：固件、开机时长、电量、两块盘的空间、内存、KOReader 和原系统在不在运行、自动升级有没有屏蔽、触摸芯片 5 秒内的中断数、最近的内存不足记录、KOReader 最近的错误。

怎么看：

- **内存**：看 `-/+ buffers/cache` 那一行的 free。Oasis 一代省内存启动后约剩 350 MB；Paperwhite 一代刚启动约剩 160 MB，读了一会书后约剩 110 MB。
- **触摸中断**：手不碰屏幕时应该是 0。不是 0 见下面“点了没反应”。
- **电量**：Oasis 一代的机身电池很小，靠充电保护套供电，读数会跳，见排错。

## 定期做的事

| 多久 | 做什么 |
| --- | --- |
| 每次大改之前 | 备份设置（见下一节） |
| 每月 | 跑一次体检；看数据盘剩余空间 |
| 每月 | KOReader 里检查更新；更新前先备份 |
| 有空 | 把电脑上的书和备份再复制一份 |
| 屏幕不灵时 | 先擦屏，再查 |

## 备份

要备份的东西都在 `/mnt/us`：

| 路径 | 内容 |
| --- | --- |
| `documents/` | 书。每本书旁边的 `书名.sdr/` 文件夹存着 KOReader 的阅读进度、划线、笔记 |
| `fonts/` | 自己加的字体 |
| `koreader/settings.reader.lua` | KOReader 的大部分设置，包括锁屏 |
| `koreader/settings/` | 插件设置、手势（`gestures.lua`）、阅读统计（`statistics.sqlite3`） |
| `koreader/history.lua` | 最近读过的书 |
| `screensaver/` | 锁屏图 |

最简单：USB 连电脑，把这些文件夹整个复制出来。

用 SSH 只备份设置（几 MB，很快）：

```
ssh -p 2222 root@<IP> 'tar -C /mnt/us -cf - koreader/settings koreader/settings.reader.lua koreader/history.lua' > kindle-settings-$(date +%Y%m%d).tar
```

`koreader/settings/weread.lua` 里有微信读书的 API Key。备份只放自己电脑，不要发给别人，不要传到公开的地方。

改设置文件前，先退出 KOReader。KOReader 开着的时候改了没用，它退出时会把内存里的设置写回去，覆盖你的修改。

## 防止自动升级

自动升级可能冲掉越狱。

- **Paperwhite 一代（5.6.1.1）**：它已经不能登录亚马逊账号，但系统的升级程序 `otaupd` 还在运行（`initctl list` 能看到 `otaupd`、`otav3`）。能不能在没注册的情况下下载升级，我们不确定。保险起见，在数据盘根目录新建一个**文件夹**，名字叫 `update.bin.tmp.partial`。KindleModding 说 5.10 及以前的固件可以用这个办法挡住升级。我们没验证过它有没有效。以后要手动升级固件时，先把它删掉。
- **Oasis 一代（WinterBreak2）**：KindleModding 说 WinterBreak 一类的越狱已经挡住了自动升级，不用另外处理。
- 根目录出现不是你放的 `.bin` 文件，先删掉，不要重启。
- 每次升级固件后，在书架里点一次 **Run Hotfix**。

来源：[KindleModding：Disabling OTA Updates](https://kindlemodding.org/jailbreaking/Legacy/post-jailbreak/disable-ota.html)

## 更新 KOReader 和插件

- **KOReader**：在 KOReader 主菜单里找“更新”，检查更新。具体位置随版本变。更新前先备份设置。更新后插件和设置都会保留，我们没实测过跨大版本的更新。
- **插件**：下载新版，核对 SHA256，把 `koreader/plugins/` 里的旧文件夹整个换掉，重启 KOReader。插件的设置在 `koreader/settings/`，不会被换掉。
- 从 Mac 拷文件后，删掉 Mac 生成的 `._` 文件：`find /Volumes/Kindle -name '._*' -delete`。

## 清理空间

```
ssh -p 2222 root@<IP> 'du -sm /mnt/us/* 2>/dev/null | sort -n | tail -15'
```

常见占地方的：

- `koreader/cache/`：封面和排版缓存，可以删，KOReader 会重新生成。删之前先退出 KOReader。
- 根目录的 `wininfo_screenshot_*.txt`：在原系统里截图时附带生成的，可以删。
- `.Spotlight-V100`、`.Trashes`、`._*`：Mac 生成的，可以删。
- 字体：中文字体一个就十几 MB，不用的可以挪回电脑。

## 远程截屏

屏幕内容在 `/dev/fb0`，8 位灰度：

| 设备 | 每行字节 | 可见区域 |
| --- | --- | --- |
| Paperwhite 一代 | 768 | 758×1024 |
| Oasis 一代 | 1088 | 1072×1448 |

```
ssh -p 2222 root@<IP> 'dd if=/dev/fb0 bs=1088 count=1448' > fb.raw
```

```
from PIL import Image
d = open("fb.raw", "rb").read()
Image.frombytes("L", (1088, 1448), d).crop((0, 0, 1072, 1448)).save("screen.png")
```

截图前想一下屏幕上有没有书单、账号、别人的昵称。发出去之前先涂掉。

## 排错

### KOReader 卡死、点不动

1. 等半分钟。墨水屏会停在旧画面上，不一定是死机。
2. 远程重启 KOReader，不用重启 Kindle。SSH 会在 KOReader 退出时断开，所以写成脚本，用 `setsid` 放到后台跑（`nohup` 会在 SSH 断开时被杀掉）：

   ```
   ssh -p 2222 root@<IP> 'cat > /tmp/restart-ko.sh <<"EOF"
   killall -TERM reader.lua
   i=0; while pidof reader.lua >/dev/null && [ $i -lt 30 ]; do sleep 1; i=$((i+1)); done
   i=0; while ! pidof cvm >/dev/null && [ $i -lt 120 ]; do sleep 1; i=$((i+1)); done
   sleep 10
   /mnt/us/documents/KOReader-lowmem.sh
   EOF
   setsid sh /tmp/restart-ko.sh </dev/null >/tmp/restart-ko.log 2>&1 &'
   ```

   这个脚本在 Oasis 一代上用过。Paperwhite 一代把最后一行换成 `/mnt/us/koreader/koreader.sh --kual --framework_stop`，这是 KUAL 菜单里 Start KOReader (no framework) 实际运行的命令（读自 `extensions/koreader/menu.json`），我们没用这种方式远程启动过。
3. 还不行：长按电源键约 40 秒强制重启。不会丢书。

这样重启，这本书最近几分钟加的划线可能没保存。能在 KOReader 里正常退出，就正常退出。

### 点了没反应、乱点、前光自己开关

1. 擦屏。用干的眼镜布或超细纤维布，四边和四个角多擦几下。Oasis 一代上的“幽灵触点”就是擦屏解决的。
2. 跑体检，看触摸中断数。手不碰屏幕，它应该是 0；一直在涨，就是有假触点。拔掉充电线再测一次，排除充电器干扰。
3. 不要写 KOReader 补丁去过滤触摸，我们试过，挡住了顶部菜单。

触摸芯片：两台都是 Cypress 的电容屏。Oasis 一代的中断名是 `main_ttsp_core.cyttsp4_i2c_adapter`，Paperwhite 一代是 `cyttsp`。体检脚本会自己找。

### 退出 KOReader 后原系统点不动

原系统刚重新启动，还没缓过来。等一两分钟；不行就长按电源键选“重启”；开着 SSH 的话也可以远程运行启动脚本，直接回到 KOReader。

### KOReader 突然退出，像重启了一样

可能是内存不足被系统杀掉：

```
ssh -p 2222 root@<IP> 'dmesg | grep -i "out of memory" | tail'
```

有记录就是内存不足。Paperwhite 一代整本书匹配微信读书划线时遇到过，改成一次两三章就好了。

也可能是 KOReader 崩溃：看 `crash.log` 末尾的 `stack traceback`。

### 电量乱跳（Oasis 一代）

机身电池很小，主要靠保护套供电。`lipc-get-prop com.lab126.powerd battLevel` 和 `/sys/class/power_supply/` 下的读数会差很多（见过 72 对 20）。平时装着保护套用。外观正常、没鼓包，就先不用管。

### 时间不对

没登录账号的 Kindle 不会自动校时。KOReader 有“时间同步”插件（timesync），联网后在工具菜单里同步一次。

### 越狱好像没了

书架里还能看到 KUAL（或 Kindle Unified Application Launcher）和 Run Hotfix，就还在。升级过固件的话，先点一次 Run Hotfix。

## 千万别做

- **恢复出厂设置。** 会清掉越狱和书。2012 年及更早的型号已经不能登录账号，书丢了没法重新下载。
- 打开 SSH 的“不使用密码登录”。同一网络里谁都能以 root 身份进来。
- 往系统盘 `/` 里写东西，或者运行来路不明的脚本。
- 把 `weread.lua`、API Key、cookies 发给别人。
