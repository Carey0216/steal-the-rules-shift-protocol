<p align="center"><img src="../../assets/icon.svg" width="112" height="112" alt="SHIFT PROTOCOL のロゴ"></p>
<h1 align="center">STEAL THE RULES: SHIFT PROTOCOL</h1>

![Version 1.2.0](https://img.shields.io/badge/version-1.2.0-4caa94) ![Godot 4.7.2](https://img.shields.io/badge/Godot-4.7.2-478cbf) ![Platform Windows and Web](https://img.shields.io/badge/platform-Windows%20%7C%20Web-30363d) [![MIT license](https://img.shields.io/badge/license-MIT-cc8850)](../../LICENSE)

[English](../../README.md) · [中文（简体）](../../docs/readme/zh-CN.md) · [中文（繁體）](../../docs/readme/zh-TW.md) · **日本語** · [한국어](../../docs/readme/ko.md)

戦いのルールを奪う 2D ボスラッシュ。GitHub Game Off 2026 向けに Godot と GDScript で制作しました。

## ゲームの特徴

| 機能 | 内容 |
| --- | --- |
| SHIFT で交換 | 攻撃を回避して開いたコアに近づき、**Shift** を押します。ボスの能力を奪い、持っていたルールを相手に渡します。 |
| 6 つの区画 | 第 2 区画の床が崩れると上下のルートを使い分けられます。その先には交互に通電する導管、溶鉱炉の噴出口、直前の位置を狙う反射攻撃、渡したルールを強化する執行機が待っています。 |
| 区画マップとセーブ | クリアすると自動保存され、次の区画が解放されます。クリア済みの区画へロビーから再挑戦でき、タイム、被弾、再挑戦回数を確認できます。Esc で一時停止、歯車から保存して終了できます。 |
| 順番に学べるガイド | 初回起動時に 5 本のプレイ映像を順に視聴します。ロビーの **？** で見直せます。各レッスンの操作を練習場で試せます。 |
| 設定 | 言語、画面モード、ウィンドウサイズ、文字サイズを変更できます。音声、動きの軽減、アシストも切り替えられます。Windows 版は初回に全画面で起動し、以降は設定を保存します。Web 版はページ内で起動し、設定から全画面にできます。 |

![2 区画をクリアしたマップ](../map.png)

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

Windows では ZIP 全体を展開して `ShiftProtocol.exe` をダブルクリックします。隣の `runtime` フォルダはそのまま残してください。デスクトップのブラウザーでは、ゲーム画面をクリックしてから操作してください。ソースから起動するには、標準版 Godot 4.7.2 で `project.godot` を開き F5 を押します。ビルド手順にはエクスポートテンプレート、テスト、Web 版と Windows 版の ZIP 作成方法があります。

[タグ付きリリースをダウンロード](https://github.com/Carey0216/steal-the-rules-shift-protocol/releases) · [ビルド手順（英語）](../BUILD.md) · [Game Off 2026](https://itch.io/jam/game-off-2026)

## クレジットとライセンス

Carey が GitHub Game Off 2026 向けに制作しました。OpenAI Codex は設計、GDScript、手続き的に生成する映像・音声、テスト、文書作成を補助しました。ゲーム実行中に AI は使用しません。独自のプロジェクトファイルは MIT ライセンスです。Barlow Condensed、Space Mono、Noto Sans をサブセット化した Shift Sans の各フォントに SIL Open Font License が付属します。Godot と依存ライブラリのライセンスは別途記載しています。

[MIT](../../LICENSE) · [SIL OFL](../../assets/) · [Godot](../GODOT_COPYRIGHT.txt)
