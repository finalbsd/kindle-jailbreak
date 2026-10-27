# Changelog

## 2026-10-27

- 首次整理成仓库，包含两台设备：Kindle Oasis 一代、Kindle Paperwhite 一代。
- Paperwhite 一代（序列号 B024 开头，固件 5.6.1.1，未登录账号）：用“降级 → K5 越狱 → 升回”的老办法在真机上越狱成功，KOReader、微信读书插件、SimpleUI 能用，已测 SSH 远程。官方 WinterBreak2 方法在这台上实测无效，原因和排错写在指南里。
- Oasis 一代（固件 5.16.2.1.1）：2026-10-25 用 WinterBreak2 越狱成功，KPM 装 KOReader（整理自当天的过程记录，未重新实机验证）。
- `devices/paperwhite1/fetch-files.sh`：下载越狱要用的文件并核对 SHA256。已验证：脚本语法；SHA256 清单与当天下载的文件一致。**未验证**：在干净环境里从头跑一遍。
- 已验证和未验证的区别见各设备指南末尾。
- 用户需要做的升级动作：无（首次发布）。
