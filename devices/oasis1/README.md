# Kindle Oasis 一代（2016）越狱

适用：Kindle Oasis 第一代（2016，带可拆卸充电保护套），固件 5.16.2.1.1。

实测结果（2026-10-25）：用 WinterBreak2 越狱成功，KPM 装上 KOReader。全程约 1 小时，其中大半是等 Kindle 充电和 USB 写入。

## 适用范围

| 项目 | 内容 |
| --- | --- |
| 型号 | Kindle Oasis 第一代（第 8 代，2016），设备代号 0GC，社区代号 KOA |
| 固件 | 5.16.2.1.1（4097550002） |
| 方法 | WinterBreak2，不要求登录或注册亚马逊账号 |
| 官方支持表 | WinterBreak2 支持 5.6.1.1 到 5.16.3（另有 5.16.5）；这台在范围内 |
| 电脑 | macOS |
| 需要 | 能传数据的 Micro-USB 线；Wi-Fi |

这台设备当时还登录着旧亚马逊账号，所以 WinterBreak（要求已注册）也能用。选 WinterBreak2 是因为国区设备注册可能失败，用它不依赖账号。

确认型号和固件：Kindle 上点“设置 → 设备选项 → 设备信息”。也可以对照 KindleModding 官方向导：https://kindlemodding.org/jailbreak-wizard.html

## 风险

- 越狱会失去保修。
- 闲置多年的 Kindle 电池可能完全放空，插电脑没有任何反应。先充电。
- 步骤里需要在 Kindle 屏幕上点的，只能你自己点。

## 步骤

### 1. 充电唤醒

闲置几年的电池可能深度亏电。插 Mac 后系统里完全看不到 Kindle，不是驱动问题，是电池空了。

1. 用充电器先充一阵，长按电源键唤醒。
2. 电量 0% 时，Mac 能识别到“Amazon Kindle”USB 设备，但**不会挂载磁盘**。要充到一定电量、重插线后，访达里才出现 Kindle 盘。
3. 越狱前最好充到 30% 以上。我们电量低时，Kindle 提示电量不足，拒绝下载，反应也很慢。

### 2. 查型号，开飞行模式

1. 开机后马上打开飞行模式，防止自动升级。
2. 设置 → 设备选项 → 设备信息，确认型号和固件版本。

### 3. 拷越狱文件

1. 下载 `wb2.zip`：

   ```
   curl -L -o wb2.zip https://github.com/KindleModding/Winterbreak2/releases/latest/download/wb2.zip
   ```

2. 压缩包里只有一个文件：`winterbreak2/dialoger.html`（627 字节）。它的原理是调用 Kindle 自带的传输服务，从 kindlemodding.org 下载 `jb.sh` 并以系统权限执行。我们这次用的版本哈希：
   - `wb2.zip` 的 sha256：`9e85970902a1f2af6b4c3243755d80595dd36404b85083f8be8c65a69d04cfdf`（作者发新版后会变，只供对照）
   - `dialoger.html` 的 sha256：`9d42a3c880bc6e6a7013a2f59e2d5e8525b369880384384d1c3d856fe7a6bbd5`
3. 把 `winterbreak2` 文件夹解压到 Kindle 根目录。

   ```
   unzip -o wb2.zip -d /Volumes/Kindle
   find /Volumes/Kindle -name '._*' -delete
   ```

### 4. 塞满存储，防自动升级

越狱要连 Wi-Fi，这期间 Kindle 可能自动下载升级包，把越狱打断。办法是先把存储塞满，让它没地方放。

1. 确认根目录里没有 `update*.bin`。
2. 在 Kindle 根目录写一个占位文件，只留约 70 MB 空闲（官方建议 50–90 MB）：

   ```
   FREE=$(df -k /Volumes/Kindle | tail -1 | awk '{print $4}')
   dd if=/dev/zero of=/Volumes/Kindle/filler.bin.dat bs=1m count=$(( FREE/1024 - 70 ))
   ```

   Kindle 的 USB 写入很慢，我们写了约 1 GB，用了几分钟。

### 5. 连 Wi-Fi，运行越狱

1. 推出磁盘，拔线。关掉飞行模式，连上 Wi-Fi。
2. 打开体验版浏览器：主页菜单里的“Experimental Browser”，或设置 → 设备选项 → 高级选项里。
3. 在浏览器里打开 `https://penguins184.xyz/wb2`。
4. 页面上只有一个 **Jailbreak** 按钮，点它。
5. 只会弹出一个“文件下载好了”的提示。这是正常现象，不是失败：下载提示是 Kindle 的传输服务在运行脚本时弹的。
6. 几十秒后屏幕上一行行滚过日志（`Stopping OTA`、`Unpacking KMC`、`Establishing Gandalf links` 等），随后显示 `Restarting Kindle`，Kindle 自动重启。
7. 重启后图书馆里出现一个叫 JAILBROKEN 的文档，内容是 `You are jailbroken! (jb.sh v2.2.1) … Winterbreak2 Jailbreak`。

如果点完 Jailbreak 后什么都没有，不要反复点。先看 [../paperwhite1/README.md](../paperwhite1/README.md) 的排错表：老固件的浏览器会把文件名里的脚本“消毒”，这个方法就不起作用。

### 6. 清理，装 KOReader

1. 连回 Mac，删掉根目录的 `filler.bin.dat`，可用空间恢复到约 1.1 GB。现代越狱已自动屏蔽升级，可以删。
2. 同时删根目录的 `update*.bin` 和 `update.bin.tmp.partial`（如有）。
3. 越狱自带包管理器 KPM。旧教程里的 KUAL 已过时，不用。
4. 把电量充到 30% 以上，Wi-Fi 保持开着。
5. 在主页的搜索栏里输入下面这一行，按回车：

   ```
   ;kpm update
   ```

6. 再输入：

   ```
   ;kpm install koreader
   ```

7. 图书馆里先出现 KOReader 图标，图标下显示 `downloading` 和进度。**看到图标不等于装好了**，等下载走完才能打开。
8. 输入 install 后没有明显反馈，别重复输入。我们输了两次，第二次在后台再下载一遍，要等它走完再打开 KOReader，没造成问题。

### 7. 省内存启动

KOReader 自己的 `koreader.sh` 支持 `--framework_stop`：启动时停掉 Kindle 原系统，退出时自动恢复。KPM 的启动脚本会把参数原样传过去。

1. 新建 `documents/KOReader-lowmem.sh`（仓库里有现成的 [KOReader-lowmem.sh](KOReader-lowmem.sh)），图书馆里显示名是脚本里 `Name:` 那行的内容。
2. 内容的核心就一行：

   ```
   /var/local/kmc/bin/kpm launch koreader --framework_stop
   ```

   仓库里的版本在这一行外面加了一层：KOReader 崩溃退出时自动再打开，10 分钟内最多 3 次；正常退出不重开。
3. 效果：程序实际占用（已用减去缓冲和缓存）从约 268 MB 降到约 162 MB。原系统的 `cvm`（约 109 MB）和 `KPPMainApp` 停掉后消失。这是在这一台上测的，别的设备数字会不同。

小坑：通过 SSH 往 Kindle 写中文文件名，在它的文件系统上会变成问号。文件名用英文，中文名写在脚本的 `# Name:` 注释里。

## 之后

装微信读书、首页、SSH 等插件，见 [../../docs/koreader-and-plugins.md](../../docs/koreader-and-plugins.md)。

## 在这台上额外遇到的问题

| 现象 | 原因 | 怎么办 |
| --- | --- | --- |
| 点菜单没反应，乱截屏 | 屏幕上有“幽灵触点”（静止的假手指），不是内存或插件慢 | 我们写了一个补丁 `2-crash-guards.lua`，把静止超 5 秒的触点记下来。**没放进仓库**，只在 Oasis 上遇到过，其他设备不一定有 |
| 想远程点屏幕做测试 | 往 `/dev/input/event3` 写多点触控事件可以模拟，但和真实手指撞在一起时手势状态会卡住 | 作者在读书时不要远程点屏幕 |
| KOReader 屏幕顶部偶尔叠着系统的时钟和电量 | 原系统的状态栏还在画 | 用省内存启动（停掉原系统）即可 |
| 在 Kindle 上截图，Mac 里看不到 | USB 模式下新截的图不会出现在 Mac 上 | 断开再截，下次挂载时拷出来 |
| Oasis 没有主页键 | 机身没有 | 点屏幕顶部，再点工具栏里的小房子 |

## 官方参考

- WinterBreak2：https://kindlemodding.org/jailbreaking/WinterBreak2/
- KindleModding 的 What's Next（KPM 装 KOReader）：https://kindlemodding.org/jailbreaking/whats-next/getting-koreader/
