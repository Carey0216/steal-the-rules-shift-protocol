# STEAL THE RULES: SHIFT PROTOCOL

[English](../../README.md) · [简体中文](zh-CN.md) · [繁體中文](zh-TW.md) · [日本語](ja.md) · [한국어](ko.md)

一款围绕规则交换展开的 2D 动作游戏。按下 SHIFT，夺取首领的能力，同时把自己的规则交给它。

[下载 Windows 版](https://github.com/Carey0216/steal-the-rules-shift-protocol/releases/latest/download/shift-protocol-windows-x64.zip) · [下载网页版](https://github.com/Carey0216/steal-the-rules-shift-protocol/releases/latest/download/shift-protocol-web.zip) · [v1.7.0](https://github.com/Carey0216/steal-the-rules-shift-protocol/releases/tag/v1.7.0)

## 开始游戏

Windows 版解压后运行 **ShiftProtocol.exe**，保留旁边的 `runtime` 文件夹。网页版可上传 itch.io，或通过本地 HTTP 服务打开 `index.html`；请使用桌面浏览器。

## 两种玩法

**协议挑战**：连续迎战六位首领。过关后继承规则、回复最多三点装甲，失败可从当前首领重试。每位首领在 67% 和 34% 血量处切换战斗阶段。

**行动战役**：八个区域、48 关，进度自动保存。首领战之间穿插相位平台、锚点换位、移动渡台、货物接力和守卫截击。

先观察攻击预警，闪避或跳出危险区，再靠近暴露的核心。交换前会预告双方得到的规则。按 **SHIFT** 交换，按 **E** 使用能力：RUSH 交换站位并向前冲斩；LIFT 让首领落地、让自己升空；AEGIS 剥离装甲，并能挡下近处的一击反弹伤害。

## 操作

| 操作 | 键盘 | 手柄 |
| --- | --- | --- |
| 向左／向右 | A / D | Stick / D-pad |
| 跳跃 | Space | A |
| 挥刀，可按住连续攻击 | J | X |
| 闪避 | K | B |
| 交换规则 | Shift | RB |
| 使用能力 | E | Y |
| 暂停 | Esc | Start |
| 重试 | R | Back |
| 确认战斗简报 | Enter | A |

键盘操作可以重设。设置还提供大字号、辅助模式、减少动态效果、分项音量和震屏强度。行动档案里可以重看实战示范，也可以进入练习。

## MONEY：实验性金币修改

用于直接尝试不同装备，不必反复刷关攒金币。

1. 在大厅，**2.4 秒内连续点击金币余额五次**。
2. 输入 **MONEY** 并确认。
3. 出现「请输入修改金币数」后，输入 **0～999999999** 之间的整数，再次确认。

修改的是存档中的金币余额，不会解锁关卡或改变星级。游戏内保留隐藏入口。

## 游戏画面

![lobby](../lobby-zh-CN.png)

![map](../map-zh-CN.png)

![equipment](../equipment-zh-CN.png)

![guide](../guide-zh-CN.png)

## 从源码运行

使用 **Godot 4.7.2 标准版**打开 `project.godot`，按 F5 运行。导出说明见 [BUILD.md](../BUILD.md)。

## 制作与许可

Carey 制作。Codex 协助编程、设计、程序绘图与音频、翻译和文档；角色原画、动作图集和大厅背景使用 OpenAI 图像生成。游戏运行时不使用 AI。详见 [AI 使用说明](../AI-DISCLOSURE.md)和[素材记录](../../assets/ART-NOTES.txt)。

原创项目文件采用 [MIT](../../LICENSE) 许可，字体和 Godot 保留各自许可。
