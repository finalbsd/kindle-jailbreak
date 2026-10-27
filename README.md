# kindle-jailbreak

两台 Kindle 的越狱操作记录。每一步都在真机上做过，失败的尝试和原因也写在里面。

越狱之后装 KOReader，还可以装微信读书、带封面的首页，并让电脑远程看屏幕。

## 先找你的型号

| 设备 | 固件 | 方法 | 要不要亚马逊账号 | 指南 |
| --- | --- | --- | --- | --- |
| Kindle Oasis 第一代（2016） | 5.16.2.1.1 | WinterBreak2 | 不要 | [devices/oasis1](devices/oasis1/README.md) |
| Kindle Paperwhite 第一代（2012） | 5.6.1.1 | 降级到 5.4.4.2 → K5 越狱 → 升回 | 不要，也登不上 | [devices/paperwhite1](devices/paperwhite1/README.md) |

不在表里的型号，先用官方向导查：https://kindlemodding.org/jailbreak-wizard.html 。仓库里的方法不一定适用，别照搬。

**型号怎么看**：Kindle 上点“设置 → 设备信息”，看序列号前几位和固件版本。也可以连电脑后读磁盘根目录里 `system/version.txt`。

## 越狱之后

- [KOReader 装好之后：微信读书、首页、SSH](docs/koreader-and-plugins.md)

## 给 AI 助手

如果你是被用户叫来帮忙越狱的 AI 助手，先读 [AGENTS.md](AGENTS.md)。里面写了哪些步骤你能做、哪些必须用户自己做、哪些要先问。

## 重要提醒

- 越狱有风险：会失去保修，操作失误可能让设备无法开机。降级和升级用的是亚马逊官方固件，风险低但不是零。
- 这个仓库不提供固件。固件、越狱包和插件的下载地址和哈希都写在各设备指南里，由你自己下载并核对。
- 仓库里的内容是操作记录，不构成保证。设备坏了没人负责，包括作者。
- 与亚马逊没有任何关系。

## 记录里的几条经验

- 官方支持表写“支持”，不等于每台都行。看看你的型号在 GitHub issue 里有没有人遇到过同样的问题。
- 亚马逊在 2026-05-20 停止了 2012 年及更早型号的支持，这些机器不能再登录账号。凡是要求“已注册”的方法对它们无效。
- 越狱文件拷进 Kindle 后，**不要急着推出磁盘**，保持 USB 驱动器模式，按教程的步骤触发。
- 墨水屏断电后会保留旧画面。屏幕上还写着“USB 驱动器模式”，不等于它没在重启。
- 拍照要拍序列号和 MAC 的话，发出去之前先涂黑。

## 目录

```
devices/oasis1/        Oasis 一代：WinterBreak2 + KPM 装 KOReader
devices/paperwhite1/   Paperwhite 一代：老办法，含下载脚本、哈希、照片
docs/                  越狱之后的 KOReader 插件
AGENTS.md              给 AI 助手的操作规则
CHANGELOG.md           更新记录
```

## 许可

文档和脚本用 MIT 许可（见 [LICENSE](LICENSE)）。仓库里提到的第三方软件（KOReader、KUAL、热修复、越狱包、各插件）各自有许可，我们不重新分发它们。
