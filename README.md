# 联想 Legion Y7000P IRX10（83NN）· macOS 15 Sequoia 黑苹果

**中文** · [English](README.en.md)

一套**实际跑起来过**的 OpenCore EFI 与完整现场笔记：在联想 Legion Y7000P IRX10（`i9-14900HX` +
**NVIDIA RTX 5060 Laptop**，由 **NullMoth** 驱动）上，把 **macOS 15 Sequoia** 作为第二系统
与 Windows 11 并存安装 —— 用的是**划出来的 256 GB 分区**，没有抹掉整块盘。

里面所有东西都来自那支真正装成了的 U 盘。写这个仓库的目的，和它参照的那份 Pro 5 笔记一样：
**每个部件是从哪来的、改了什么、为什么改、什么能用、以及弄坏了之后怎么回到能开机的状态。**

`EFI/` 里是可用的真实副本，只把 Mac 身份换成了占位符 —— `SystemSerialNumber`、`MLB`（主板序列号）、
`SystemUUID`、`ROM` 都是占位值。**用之前请自己用 GenSMBIOS 生成**，见
[docs/mac-identity.md](docs/mac-identity.md)。

---

## 这台机器是怎么装成的

五步，按实际发生的顺序。每一步的细节都在 `docs/` 里。

| # | 步骤 | 实际做了什么 | 细节 |
|---|---|---|---|
| 1 | 确认显卡驱动 | 任何 macOS 都没有 Intel 核显驱动，所以内屏只能走独显。先确认这颗 GPU 有驱动、驱动**只覆盖 macOS 15**、且内屏物理接在独显上（于是 BIOS 能切独显直连） | [docs/nvidia-nullmoth.md](docs/nvidia-nullmoth.md) · [docs/hardware.md](docs/hardware.md) |
| 2 | 用 1401 工具做引导盘 | 一个 Windows 工具下载 macOS Sequoia 15、把本仓库的 `EFI/` 写进 FAT32 U 盘，卷标 `1401`。成品是 `EFI/` + `com.apple.recovery.boot/` + 驱动包 | [docs/install-guide.md](docs/install-guide.md#step-2--build-the-boot-stick) |
| 3 | 改 BIOS | 关 Secure Boot、关 CSM、开 Above 4G、开 Resizable BAR、**显卡模式切独显直连** | [docs/hardware.md](docs/hardware.md#bios) |
| 4 | 首次启动 panic → 改 `config.plist` | 交付时的配置里带着三条会改动超线程的 `Kernel → Patch`，内核在交权后 0.85 秒就挂了。把它们禁用，就得到了能用的配置 | [docs/troubleshooting.md](docs/troubleshooting.md) |
| 5 | 进桌面，再装驱动 | macOS 是在完全没有显卡加速（只有 framebuffer）的状态下装完的。驱动是**进系统之后**装的，装进 `/Library/Extensions` —— EFI 里不放任何显卡相关的东西 | [docs/nvidia-nullmoth.md](docs/nvidia-nullmoth.md) |

第 4 步是大多数人会卡住的一步，也是本仓库里"排错资料比安装资料还长"的原因：一份 OpenCore 日志、
一个根因、一份与原始配置的对比。这一步是**用 [dsh](https://github.com/deepseek-ai/deepseek-harness)（DeepSeek Harness，
一个 AI 编程 Agent）**读日志、定位到那三条 `Kernel → Patch`、改好 `config.plist` 的 —— 见下面的"致谢"。

---

## 状态表

以下状态是在本机装成之后确认的。

| 项目 | 状态 | 说明 |
|---|---|---|
| 显卡 | ✅ NVIDIA RTX 5060 Laptop，Metal 加速正常 | NullMoth 1.13.0。内屏物理接在独显上，所以 **BIOS 必须切"独显直连"** |
| 引导 | ✅ 从 U 盘 OpenCore 启动（FAT32，卷标 `1401`） | 本机**至今仍从 U 盘启动**：内置 ESP 与 Windows 的任何分区都没有动过。装机当天 20 次启动日志的完整分析见 [docs/troubleshooting.md](docs/troubleshooting.md) |
| 内屏 | ✅ 2560×1600 @ 60 Hz | 面板会宣告 240 Hz，但拿不到 |
| 外接显示器 | 🟡 可用但不支持热插拔 | 独显输出的外接屏能用，但必须在开机前接好；系统运行中插上不会点亮 |
| 触控板 | ❌ 不可用 | EFI 里 VoodooI2C 那一套是齐的，但本机从没把它调通 —— 实测触控板没反应。要修的话，先试把参照机的 `VoodooI2C-RPL-GPIO` 移植过来 |
| 无线网卡 | ❌ 无驱动 | 本机这块是**自己换上的** AX1690i（`8086:7A70`），不在 `itlwm` 支持列表里，请用 USB 网卡 |
| 蓝牙 | ✅ 可用 | `IntelBluetoothFirmware` + `IntelBTPatcher` + `BlueToolFixup`，本机实测可正常连接 |
| 有线网卡 | ✅ 可用 | Realtek `10EC:8168` + `RealtekRTL8111`。有线上网就是这台机器可用的那条路 |
| 声卡 | ✅ 可用 | ALC257，`layout-id=99`；**笔记本内置音响有用**。内建麦克风**在系统测试里有反应**，但没有做过严谨测试 |
| 键盘 | ✅ | VoodooPS2Controller |
| 键盘灯 | ⚠️ 未测 | 本 EFI 没有 `LegionRGBUSBFix`，也就是没有任何东西在 macOS 里驱动 RGB 控制器；因为不太需要，所以从没测过 |
| 电池 / 传感器 | ✅ 可用 | VirtualSMC + SMCBatteryManager + SMCProcessor/SMCSuperIO，YogaSMC 接管 Legion EC：风扇在转，**Fn+Q 能切换性能模式** |
| 摄像头 | ⚠️ 未测 | 本机还没有验证过 |
| 系统休眠 | ❌ 已禁用 | 驱动唤醒后会丢显卡。屏幕休眠可用 |
| 改分辨率 | ❌ 危险 | 会让整个系统冻结。别碰"显示器"设置 |
| 亮度调节 | ❌ 无 | `AppleBacklightDisplay` 计数为 0 |
| HDMI/DP 音频 | ❌ 无 | |
| CUDA | ❌ 不可能 | 驱动里没有，macOS 生态里也没有 |
| Apple ID / iServices | ⚠️ 未测 | 需要你自己生成的三码；且 `MacBookPro16,4` 是台式机档位的 SMBIOS |

标注含义：✅ 本机已确认 · 🟡 已配置、按同代配方预期可用，但未逐项单独验证 · ❌ 在这套硬件/驱动上已知不可用 · ⚠️ 尚未验证。

---

## 仓库结构

| 路径 | 内容 |
|---|---|
| `EFI/` | 可用的 OpenCore EFI，从 U 盘逐文件拷出（不含本文未涉及的三份额外配置变体；151 个文件，约 40 MB） |
| `EFI/OC/config.plist` | 最后一次成功启动所用的配置（2026-10-11 17:23） |
| `EFI/OC/config-1401-original-BACKUP.plist` | `1401` 工具交付时的原始状态 —— 第 4 步的"改之前"；留着它，不要编辑 |
| `docs/` | 现场笔记（见下） |
| `logs/` | 两份裁剪过的 OpenCore 日志：一次 panic，最后一次干净交权 |
| `reports/nullmoth/` | 驱动安装报告：安装器自己在本机写下的机器档案，以及上游 README/MANIFEST |
| `tools/` | 用来 dump、修补、校验配置的 PowerShell / Node 脚本 |
| `SHA256SUMS` | `EFI/` 下每个文件的哈希，可用来确认你的副本没被改动 |

---

## 文档索引

| 文档 | 内容 |
|---|---|
| [docs/hardware.md](docs/hardware.md) | 精确的硬件 ID、macOS 能驱动什么不能驱动什么、BIOS 硬前提 |
| [docs/install-guide.md](docs/install-guide.md) | 五步全流程，以及哪些地方你可以按自己的情况变通 |
| [docs/opencore-efi.md](docs/opencore-efi.md) | 每个 kext 及版本、SSDT、Quirks、补丁、boot-args，以及每处与参照机的差异和原因 |
| [docs/nvidia-nullmoth.md](docs/nvidia-nullmoth.md) | 驱动本身、硬性要求、安装/卸载、从哪里获取 |
| [docs/troubleshooting.md](docs/troubleshooting.md) | 0.85 秒 panic 及其根因、Reset NVRAM 那次启动、怎么读 OpenCore 日志、恢复手段 |
| [docs/peripherals.md](docs/peripherals.md) | 触控板、无线/蓝牙、音频、摄像头、USB、硬盘、电源、显示 |
| [docs/mac-identity.md](docs/mac-identity.md) | 为什么三码是占位符，以及怎么生成自己的 |
| [docs/sources.md](docs/sources.md) | 所有上游项目、版本与下载位置 |

> 说明：`docs/` 下的详细文档目前是**英文**；这份 README 有
> [中文](README.md) / [English](README.en.md) 两个版本。

---

## 关键事实

- **机型**：联想 Legion Y7000P IRX10，主板 `LNVNB161216`，芯片组 `HM770`，EC 为 `0x5508` 代。
- **CPU**：Intel Core i9-14900HX（Raptor Lake-HX，24 核）—— 没有官方配置页，靠 `CpuTscSync` + `CpuTopologyRebuild` 撑。
- **显卡**：Intel UHD 核显（`8086:A788`，Xe）在任何 macOS 上**都没有驱动**；RTX 5060 Laptop（`10DE:2D59` / `17AA:802F`）是唯一的显示通路。
- **磁盘布局**：Windows 11 那块盘照旧保留。macOS 装在它旁边**约 256 GB 空闲空间里新建的 APFS 容器**中 —— 是分区，不是抹盘，Windows 的任何分区、共用的 EFI 系统分区都没有改过。本机至今**仍从 U 盘启动**，EFI 从未拷进内置 ESP。
- **硬前提 ①**：BIOS 显卡模式必须是**独显直连**（不能混合/Optimus）。
- **硬前提 ②**：**关闭 Secure Boot**。
- **硬前提 ③**：NullMoth 驱动的 kext 装进 `/Library/Extensions`，**不是** `EFI/OC/Kexts`。EFI 里不该放任何显卡相关的东西。
- **驱动只在 macOS 15 上工作。** 1.13.0 包声明 `runtime_minimum_macos: 15.5`，并在 15.8.1 上做了资格验证。
- 那三条改超线程的 `Kernel → Patch`（`base _cpu_thread_alloc`）在 `config.plist` 里是 `Enabled=false`。开着它会在交权后 0.85 秒内核 panic，详见 [docs/troubleshooting.md](docs/troubleshooting.md)。

---

## 致谢，以及本仓库**故意不放**的东西

这里最关键的一环不是我做的：**NullMoth** —— 让 Blackwell 世代的 RTX 5060 Laptop 在 macOS 15 下能用的
NVIDIA 驱动。没有它，这台机器就是一块黑屏。驱动的功劳、以及 U 盘上 `NullMoth/` 那套安装工具的功劳，
全部属于它的作者。

**本仓库刻意不再分发这个驱动。** U 盘上原本有 `NullMoth/nullmoth-nvidia-1.13.0.tar.gz`（269,301,262 字节）
和 `1401-Mac-1.13.0.zip`；这两个包、`pkgroot/`、以及其中任何 `.kext`/`.bundle`/`.dylib` 都没有镜像到这里。
请从项目自己的分发渠道获取并按它的说明安装。这里收录的是
[`reports/nullmoth/system-profile.json`](reports/nullmoth/system-profile.json) —— 安装器自己在这台笔记本上
写出的机器档案 —— 以及原封不动的 `README.txt` 与 `MANIFEST.txt`，这样下面的结果可以复现、可以核对，
而不必转发他人的二进制文件。

**这次的排错和这份文档都是 [dsh](https://github.com/deepseek-ai/deepseek-harness)（DeepSeek Harness）做的** ——
装这台机器时主人全程在用的那个 AI 编程 Agent。它从本机会话里读走 U 盘上那 262 KB 的 OpenCore 环形缓冲区日志，
把内核 panic 定位到三条改超线程的 `Kernel → Patch`，在 `config.plist` 里把它们禁用（就是上面第 4 步），
然后整理出了这个仓库 —— 文档、脱敏后的配置、`SHA256SUMS`。**修好它的功劳在这里**；
硬件、刷盘、装驱动则是主人自己动手的部分。

同样要感谢 OpenCore 团队和 [docs/sources.md](docs/sources.md) 里列出的所有 kext 作者，以及
[Ammarrrrrrr/legion-pro5-hackintosh](https://github.com/Ammarrrrrrr/legion-pro5-hackintosh) ——
本仓库照着它的结构写，而且它的可用配置就是这里每一处改动的对照基准。

同样不在这里的：任何带真实 Mac 身份信息的内容，以及任何许可证不允许再分发的 kext。
`EFI/OC/Kexts` 里的第三方 kext 仍归各自上游许可证（清单见 [docs/sources.md](docs/sources.md)）；
本仓库的文档部分采用 [CC BY-NC-SA 4.0](LICENSE)。

---

## 免责声明

这是一台特定机器、一个特定驱动版本的记录。黑苹果配置无法跨机型照搬，而且这个 NVIDIA 驱动明确
不允许商业用途。刷 EFI 有可能让笔记本直接开不了机；请保证 Windows 启动项始终可用，并且先在 U 盘上试。
不提供任何形式的担保。
