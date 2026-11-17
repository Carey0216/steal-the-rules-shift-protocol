<p align="center"><img src="../../assets/icon.svg" width="112" height="112" alt="SHIFT PROTOCOL のロゴ"></p>
<h1 align="center">STEAL THE RULES: SHIFT PROTOCOL</h1>

![Version 1.1.0](https://img.shields.io/badge/version-1.1.0-4caa94) ![Godot 4.7.2](https://img.shields.io/badge/Godot-4.7.2-478cbf) ![Platform Windows and Web](https://img.shields.io/badge/platform-Windows%20%7C%20Web-30363d) [![MIT license](https://img.shields.io/badge/license-MIT-cc8850)](../../LICENSE)

[English](../../README.md) · [中文（简体）](../../docs/readme/zh-CN.md) · [中文（繁體）](../../docs/readme/zh-TW.md) · **日本語** · [한국어](../../docs/readme/ko.md)

戦いのルールを奪う 2D ボスラッシュ。GitHub Game Off 2026 向けに Godot と GDScript で制作しました。

## ゲームの特徴

| 機能 | 内容 |
| --- | --- |
| SHIFT で交換 | 攻撃を回避して開いたコアに近づき、**Shift** を押します。ボスの能力を奪い、持っていたルールを相手に渡します。 |
| 3 体のボス | 監視機、格子機、執行機に挑みます。第 2 区画で LIFT を奪うと床が崩れます。 |
| プレイ映像つきガイド | 初回起動時に言語を選び、移動、ジャンプ、斬撃、回避、ルールの奪取と使用を実際のプレイ映像で確認できます。タイトル画面の **？** でいつでも見直せます。 |
| 設定 | 言語、画面モード、ウィンドウサイズ、文字サイズを変更できます。音声、動きの軽減、アシストも切り替えられます。Windows 版は初回に全画面で起動し、以降は設定を保存します。Web 版はページ内で起動し、設定から全画面にできます。 |

![操作ガイドに表示された実際のプレイ映像](../guide.png)

## 操作方法

| 操作 | キーボード | コントローラー |
| --- | --- | --- |
| 開始 / 続ける | Enter | Start / A |
| 移動 | A/D または矢印キー | 左スティック / 十字キー |
| ジャンプ | Space、W または ↑ | A |
| 斬撃（長押しで連続） | J または Z | X |
| 回避 | K または X | B |
| 奪取 / 交換 | Shift または Q | 右バンパー |
| 現在のルールを使う | E または C | Y |
| 一時停止 | Esc または P | Start |
| 現在の区画をやり直す | R | Back / Select |

## ルールと回復

**RUSH** は前方への突進斬り。**LIFT** は上昇し、その間に斬撃を出すと装甲を貫けます。**AEGIS** は攻撃を一度受け止め、ボスが近ければダメージを返します。次のボスの攻撃が終わるか、奪取が成功すると再使用できます。次の区画に入ると耐久が最大 3 回復します。やり直すと区画に入った時点の状態に戻ります。

## 起動とビルド

Windows では ZIP 全体を展開し、`ShiftProtocol.pck` と同じフォルダにある `ShiftProtocol.exe` を実行します。デスクトップのブラウザーでは、ゲーム画面をクリックしてから操作してください。ソースから起動するには、標準版 Godot 4.7.2 で `project.godot` を開き F5 を押します。ビルド手順にはエクスポートテンプレート、テスト、Web 版と Windows 版の ZIP 作成方法があります。

[ビルド手順（英語）](../BUILD.md) · [Game Off 2026](https://itch.io/jam/game-off-2026)

## クレジットとライセンス

Carey が GitHub Game Off 2026 向けに制作しました。OpenAI Codex は設計、GDScript、手続き的に生成する映像・音声、テスト、文書作成を補助しました。ゲーム実行中に AI は使用しません。独自のプロジェクトファイルは MIT ライセンスです。Barlow Condensed、Space Mono、Noto Sans をサブセット化した Shift Sans の各フォントに SIL Open Font License が付属します。Godot と依存ライブラリのライセンスは別途記載しています。

[MIT](../../LICENSE) · [SIL OFL](../../assets/) · [Godot](../GODOT_COPYRIGHT.txt)
