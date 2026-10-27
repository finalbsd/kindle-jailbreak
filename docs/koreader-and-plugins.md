# KOReader 装好之后：微信读书、首页、SSH

适用：已按 [Oasis](../devices/oasis1/README.md) 或 [Paperwhite 一代](../devices/paperwhite1/README.md) 越狱、KOReader 已能启动的 Kindle。以下都是 KOReader 插件，装在 `koreader/plugins/` 里，删文件夹即可回退。

插件目录在 Kindle 磁盘的 `koreader/plugins/`。装完要**重启 KOReader** 才生效。

## 1. 微信读书（weread.koplugin）

| 项目 | 内容 |
| --- | --- |
| 作者 | finlater，AGPL-3.0 |
| 版本 | v1.6.0（2026-10-05 发布） |
| 要求 | KOReader 2026.03 以上 |
| 下载 | https://github.com/finlater/weread.koplugin/releases/download/v1.6.0/weread.koplugin-v1.6.0.zip |
| 官方哈希文件 | 同目录下 `weread.koplugin-v1.6.0.zip.sha256` |
| sha256 | `647abca30fe7638d67c5c24e483409acdedaa758194f177863d1385365258d51` |

步骤：

1. 下载后用 `shasum -a 256` 核对哈希。
2. 解压到 Kindle 的 `koreader/plugins/`，得到 `weread.koplugin/`，共 91 个文件。
3. 删掉 macOS 生成的 `._` 文件：`find /Volumes/Kindle -name '._*' -delete`。
4. 手机微信读书 App：我 → 设置 → 微信读书 Skill，确认它已开启。
5. Kindle 上启动 KOReader，连 Wi-Fi。工具菜单里找“微信读书”，选“微信扫码登录”，用手机微信扫码并确认。显示四位验证码的话，在 KOReader 里输入。

登录成功后插件自己取得 API Key，存在 `koreader/settings/weread.lua`（明文）。**这个文件和 API Key 是你账号的凭证，不要放进仓库、不要发给别人、不要贴进聊天。**

实测：登录后书架同步成功。

风险：这是第三方插件，作者声明账号封禁等后果由用户自负。

## 2. SimpleUI（带封面的首页，底栏自动加微信读书入口）

| 项目 | 内容 |
| --- | --- |
| 作者 | joeseesun，GPL-3.0，基于 Doctor Hetfield 的 SimpleUI 3.0.0 |
| 版本 | v3.0.0-qiaomu.3（测试版，2026-10-24） |
| 下载 | https://github.com/joeseesun/qiaomu-simpleui/releases/download/v3.0.0-qiaomu.3/simpleui.koplugin.zip |
| sha256 | `b510d7552f2aeeb1b39a0c8b9ccdcc673bdec7bc22ed7d0204eeb9e30d3c8c38` |
| 文件数 | 301 个 |

解压到 `koreader/plugins/simpleui.koplugin/`，重启 KOReader，在设置里把它设为主页。

日志里会有两条警告，不影响使用：首次引导页的“预设”页报错（`buildListRows` 为空），检查更新 HTTP 404。

注意：它和觅阅（MiuRead）的“桌面模式”冲突，两个都想接管首页和手势。要同时用，觅阅用“插件模式”，切换后要重启两次 KOReader 才生效。

内存紧的设备（比如 Paperwhite 一代只有 256 MB）要不要装，自己权衡。

## 3. 远程看屏幕、读日志（SSH）

KOReader 自带 SSH 服务器（dropbear，端口 2222），只认公钥。

1. 在 Kindle 的 `koreader/settings/SSH/` 里放一个 `authorized_keys`，内容是电脑的公钥（例如 `~/.ssh/id_ed25519.pub`）。**这等于给设备留一个登录入口，只给自己的电脑放，且要你自己明确同意。**
2. Kindle 上：KOReader → 工具 → 更多工具 → SSH 服务器 → 启动，屏幕上会显示 IP。
3. 电脑上：`ssh -p 2222 root@<Kindle 的 IP>`。

不要打开“不使用密码登录（危险）”。那样同一网络里的任何设备都能以 root 身份进来。

### 远程截屏

Kindle 屏幕内容在 `/dev/fb0`（8 位灰度）。Paperwhite 一代每行 768 字节，可见区域 758×1024：

```
ssh -p 2222 root@<IP> 'dd if=/dev/fb0 bs=768 count=1024' > fb.raw
```

用 Python 的 Pillow 转成图片：

```
from PIL import Image
d = open("fb.raw", "rb").read()
Image.frombytes("L", (768, 1024), d).crop((0, 0, 758, 1024)).save("screen.png")
```

Oasis 的屏幕更大（可见 1072×1448，每行 1088 字节），参数不同，自己用 `cat /sys/class/graphics/fb0/stride` 和 `virtual_size` 读。

### 看内存

Kindle 自带的是 BusyBox，命令和 Linux 不完全一样（比如 `sed` 没有 `-E`）：

```
ssh -p 2222 root@<IP> 'free -m'
```

看 `-/+ buffers/cache` 那一行，才是程序实际占用。

## 4. 没放进仓库的东西

- **wereadhl.koplugin**：作者自己写的“把自己的微信读书划线导进 KOReader 原书”的插件。目前只在 Oasis 上试过，没整理好，未放入仓库。
- **2-crash-guards.lua**：Oasis 的“幽灵触点”崩溃保护补丁，只对那台设备有意义。
- 任何 API Key、cookies、`weread.lua`、你的书单和划线数据。
