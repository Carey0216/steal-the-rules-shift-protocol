<p align="center"><img src="../../assets/icon.svg" width="112" height="112" alt="SHIFT PROTOCOL 標誌"></p>
<h1 align="center">STEAL THE RULES: SHIFT PROTOCOL</h1>

![Version 1.1.0](https://img.shields.io/badge/version-1.1.0-4caa94) ![Godot 4.7.2](https://img.shields.io/badge/Godot-4.7.2-478cbf) ![Platform Windows and Web](https://img.shields.io/badge/platform-Windows%20%7C%20Web-30363d) [![MIT license](https://img.shields.io/badge/license-MIT-cc8850)](../../LICENSE)

[English](../../README.md) · [中文（简体）](../../docs/readme/zh-CN.md) · **中文（繁體）** · [日本語](../../docs/readme/ja.md) · [한국어](../../docs/readme/ko.md)

一款靠偷取規則改變戰局的 2D Boss Rush。為 GitHub Game Off 2026 使用 Godot 與 GDScript 製作。

## 遊戲特色

| 功能 | 遊戲中的表現 |
| --- | --- |
| SHIFT 交換 | 躲過攻擊，靠近開啟的核心並按 **Shift**。你取得 Boss 的能力，並把原有規則交給它。 |
| 三場 Boss 戰 | 迎戰監守者、懸陣機和執行者。在第二場奪走 LIFT 可以砸穿地板。 |
| 實戰錄影教學 | 首次啟動時選擇語言，觀看移動、跳躍、揮刀、閃避、偷取及使用能力的實戰錄影。點選標題畫面的 **？** 可重看。 |
| 設定 | 可變更語言、顯示模式、視窗大小及文字大小，也可切換音效、減少動態效果和輔助模式。Windows 首次啟動預設為全螢幕，之後會記住你的選擇。網頁版在頁面內啟動，可在設定切換全螢幕。 |

![操作指南中的實戰錄影](../guide.png)

## 操作方式

| 操作 | 鍵盤 | 控制器 |
| --- | --- | --- |
| 開始 / 繼續 | Enter | Start / A |
| 移動 | A/D 或方向鍵 | 左搖桿 / 十字鍵 |
| 跳躍 | 空白鍵、W 或 ↑ | A |
| 揮刀（可按住） | J 或 Z | X |
| 閃避 | K 或 X | B |
| 偷取 / 交換 | Shift 或 Q | 右肩鍵 |
| 使用目前的能力 | E 或 C | Y |
| 暫停 | Esc 或 P | Start |
| 重試目前區域 | R | Back / Select |

## 規則與修復

**RUSH** 向前衝刺斬擊。**LIFT** 向上噴射，上升時揮刀可穿透裝甲。**AEGIS** 擋下一擊，Boss 在附近時會反彈傷害。下一次 Boss 攻擊結束或交換成功後，能力會重新充能。進入新區域最多修復三格耐久，重試會恢復進入該區域時的狀態。

## 執行與建置

在 Windows 上解壓縮整個檔案，執行與 `ShiftProtocol.pck` 同一資料夾的 `ShiftProtocol.exe`。使用桌面瀏覽器時，先點選遊戲畫面讓它取得焦點。從原始碼執行時，使用標準版 Godot 4.7.2 開啟 `project.godot` 再按 F5。建置說明包含匯出範本、測試及 Web、Windows 壓縮檔的製作步驟。

[建置說明（英文）](../BUILD.md) · [Game Off 2026](https://itch.io/jam/game-off-2026)

## 製作與授權

Carey 為 GitHub Game Off 2026 製作。OpenAI Codex 協助設計、GDScript 程式、程式生成的畫面和音效、測試及文件。遊戲執行時不使用 AI。原創專案檔案採用 MIT 授權。Barlow Condensed、Space Mono 和源自 Noto Sans 的 Shift Sans 字型子集均附有 SIL Open Font License。Godot 和其相依套件附有獨立授權。

[MIT](../../LICENSE) · [SIL OFL](../../assets/) · [Godot](../GODOT_COPYRIGHT.txt)
