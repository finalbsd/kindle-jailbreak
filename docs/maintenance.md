# 日常维护手册

适用：已按本仓库越狱、装了 KOReader 并能用 SSH 连上的 Kindle。命令都在 Oasis 一代和 Paperwhite 一代上用过，个别只在一台上试过的会注明。

## 先认识这台机器

越狱后的 Kindle 就是一台 ARM 小电脑，跑的是精简的 Linux。

| 东西 | 是什么 |
| --- | --- |
| `/mnt/us` | 数据盘。USB 连电脑时看到的就是它：书、字体、KOReader 都在这里 |
| `/` | 系统盘，很小，Oasis 上已用 95%。**不要往里写东西** |
| BusyBox | 精简版的命令集。老固件（Paperwhite 一代）上 `sed`、`grep` 不支持 `-E`，要用多个 `-e`；`ps` 不显示完整命令行；没有 `scp`、`rsync` |
| `cvm` | Kindle 原系统的主程序（Java），约占 100 MB 内存 |
| `lab126_gui` | 原系统的服务名。`status lab126_gui` 看状态 |
| `powerd` | 电源管理。`lipc-get-prop com.lab126.powerd battLevel` 读电量 |
| `/var/log/messages` | 原系统日志 |
| `/mnt/us/koreader/crash.log` | KOReader 日志，名字叫 crash，平时的记录也写在这里 |

“省内存启动”（`--framework_stop` 或 KUAL 里的 `no framework`）会停掉 `cvm`，KOReader 退出时再把它启动起来。原系统重新起来要一两分钟。

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

- **Paperwhite 一代（5.6.1.1）**：它已经不能登录亚马逊账号，收不到推送。想保险，在数据盘根目录新建一个**文件夹**，名字叫 `update.bin.tmp.partial`，KindleModding 说 5.10 及以前的固件可以用这个办法挡住升级。我们没在这台上验证过。以后要手动升级固件时，先把它删掉。
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
ssh -p 2222 root@<IP> 'du -sh /mnt/us/* 2>/dev/null | sort -h | tail -15'
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

   这个脚本在 Oasis 一代上用过。Paperwhite 一代是从 KUAL 启动的，没有这个启动脚本：把最后一行删掉，重启时只关掉 KOReader，等原系统起来后自己在 KUAL 里点 Start KOReader (no framework)。
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
