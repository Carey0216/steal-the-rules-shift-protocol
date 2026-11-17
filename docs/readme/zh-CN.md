<p align="center"><img src="../../assets/icon.svg" width="112" height="112" alt="SHIFT PROTOCOL 标志"></p>
<h1 align="center">STEAL THE RULES: SHIFT PROTOCOL</h1>

![Version 1.1.0](https://img.shields.io/badge/version-1.1.0-4caa94) ![Godot 4.7.2](https://img.shields.io/badge/Godot-4.7.2-478cbf) ![Platform Windows and Web](https://img.shields.io/badge/platform-Windows%20%7C%20Web-30363d) [![MIT license](https://img.shields.io/badge/license-MIT-cc8850)](../../LICENSE)

[English](../../README.md) · **中文（简体）** · [中文（繁體）](../../docs/readme/zh-TW.md) · [日本語](../../docs/readme/ja.md) · [한국어](../../docs/readme/ko.md)

一款靠偷取规则改变战局的 2D Boss Rush。为 GitHub Game Off 2026 使用 Godot 和 GDScript 制作。

## 游戏特色

| 功能 | 游戏中的表现 |
| --- | --- |
| SHIFT 交换 | 躲过攻击，靠近开启的核心，按 **Shift**。你拿到 Boss 的能力，并把原有规则交给它。 |
| 三场 Boss 战 | 迎战监守者、悬阵机和执行者。在第二场夺走 LIFT 可以砸穿地板。 |
| 实战录像引导 | 首次启动选择语言，观看移动、跳跃、挥刀、闪避、偷取和使用能力的实战录像。点标题画面的 **？** 可重看。 |
| 设置 | 可修改语言、显示模式、窗口大小和文字大小，也可切换声音、减少动效和辅助模式。Windows 首次启动默认全屏，之后记住你的选择。网页版在页面内启动，可在设置里切换全屏。 |

![操作指南里的实战录像](../guide.png)

## 操作方式

| 操作 | 键盘 | 手柄 |
| --- | --- | --- |
| 开始 / 继续 | Enter | Start / A |
| 移动 | A/D 或方向键 | 左摇杆 / 十字键 |
| 跳跃 | 空格、W 或 ↑ | A |
| 挥刀（可按住） | J 或 Z | X |
| 闪避 | K 或 X | B |
| 偷取 / 交换 | Shift 或 Q | 右肩键 |
| 使用当前能力 | E 或 C | Y |
| 暂停 | Esc 或 P | Start |
| 重试当前区域 | R | Back / Select |

## 规则与恢复

**RUSH** 向前冲刺斩击。**LIFT** 向上喷射，上升时挥刀可破甲。**AEGIS** 挡下一击，Boss 在近处时反弹伤害。下一次 Boss 攻击结束或交换成功后，能力会重新充能。进入新区域最多恢复三格耐久，重试会恢复到进入本区域时的状态。

## 运行与构建

在 Windows 上解压整个压缩包，运行与 `ShiftProtocol.pck` 同目录的 `ShiftProtocol.exe`。使用桌面浏览器时，先点击游戏画面使其获得焦点。从源码运行时，用标准版 Godot 4.7.2 打开 `project.godot` 后按 F5。构建说明包含导出模板、测试和 Web、Windows 压缩包的制作方法。

[构建说明（英文）](../BUILD.md) · [Game Off 2026](https://itch.io/jam/game-off-2026)

## 制作与许可

Carey 为 GitHub Game Off 2026 制作。OpenAI Codex 协助了设计、GDScript 编程、程序生成的画面和音效、测试及文档。游戏运行时不使用 AI。原创项目文件采用 MIT 许可。Barlow Condensed、Space Mono 及由 Noto Sans 制作的 Shift Sans 字体子集均附带 SIL Open Font License。Godot 及其依赖附带独立许可。

[MIT](../../LICENSE) · [SIL OFL](../../assets/) · [Godot](../GODOT_COPYRIGHT.txt)
