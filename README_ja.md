[English](README.md) | [简体中文](README_zh-CN.md) | [繁體中文](README_zh-TW.md) | [日本語](README_ja.md) | [한국어](README_ko.md) | [Français](README_fr.md)

# MouseMapper

**マウスのサイドボタンを任意のキーボードキーに割り当てるツール。** macOS・Windows 両対応。

## なぜ作ったのか

Logicool（Logitech）などの多ボタンマウスを使っていると、こんな不満にぶつかりませんか？

**Logitech Options+ の問題点：**
- サイドボタンには「進む/戻る」などのブラウザ操作しか割り当てられない — **任意のキーボードキーへのマッピングは不可**
- サイドボタンを fn / Command / Alt 単体として使いたい？ 無理です
- `Ctrl+C` のようなキーコンビネーションを割り当てたい？ 非対応です
- ソフト自体が 500MB 超、常駐してメモリを消費し、ログイン・同期・アップデート通知がうるさい
- macOS ではシステムとの競合が頻発し、アップデート後にマッピングが消えることも

**他のツール：** 有料（BetterTouchTool）、設定が複雑（Karabiner）、あるいは単一プラットフォーム限定。

**だから MouseMapper を作りました：**
- exe ひとつ / バイナリひとつ、ダブルクリックで起動、依存関係ゼロ
- 任意のキーボードキーに対応 — 修飾キー単体（fn、Command/Win、Alt/Option、Shift、Ctrl）も OK
- キーコンビネーション対応（`ctrl+c`、`shift+alt`、`command+space` など）
- JSON 設定ファイルで一目瞭然、編集して再起動するだけ
- プログラム全体で 500KB 未満 — ネット接続なし、ログインなし、アップデートなし、煩わしさゼロ

## ダウンロード

**Windows:** [MouseMapper.exe をダウンロード](https://github.com/vorojar/MouseMapper/releases) — ダブルクリックで実行、自動でシステムトレイ常駐＆スタートアップ登録。

**macOS:** ソースからビルド（下記参照）。

## クイックスタート

### Windows

1. `MouseMapper.exe` をダウンロード
2. ダブルクリックで起動 → exe と同じフォルダに `config.json` を自動生成 → スタートアップを自動設定
3. `config.json` を編集してマッピングを変更、プログラムを再起動で反映
4. 右下のトレイアイコンを右クリック → スタートアップ管理 / 終了

### macOS

```bash
git clone https://github.com/vorojar/MouseMapper.git
cd MouseMapper
bash install.sh
```

初回はアクセス許可が必要です：`システム設定 → プライバシーとセキュリティ → アクセシビリティ`。

## 設定

両プラットフォーム共通の `config.json` 形式：

```json
{
  "mappings": [
    {
      "button": 3,
      "key": "return",
      "action": "click"
    },
    {
      "button": 4,
      "key": "alt",
      "action": "hold"
    }
  ]
}
```

| フィールド | 説明 |
|------------|------|
| `button` | マウスボタン番号：`2`=中央、`3`=サイド後、`4`=サイド前 |
| `key` | 割り当て先キー、`+` でコンビネーション：`return`、`ctrl+c`、`shift+alt` |
| `action` | `"click"`（デフォルト）押下で1回発火 / `"hold"` 押している間継続 |

### 対応キー

**修飾キー：** `shift`、`control`/`ctrl`、`alt`/`option`、`command`/`win`、`caps_lock`（すべて `left_`/`right_` バリアントに対応）

**macOS 専用：** `fn`

**ファンクションキー：** `f1`-`f12`

**よく使うキー：** `escape`/`esc`、`return`/`enter`、`tab`、`space`、`backspace`/`delete`、`forward_delete`、`insert`

**ナビゲーション：** `up`、`down`、`left`、`right`、`home`、`end`、`page_up`、`page_down`

**英字/数字/記号：** `a`-`z`、`0`-`9`、`-`、`=`、`[`、`]`、`\`、`;`、`'`、`,`、`.`、`/`、`` ` ``

## ユースケース

- サイド後 → `Enter` — 親指で確定、コーディングやチャットの効率倍増
- サイド前 → `Alt`（ホールドモード） — マウスドラッグと組み合わせてウィンドウ移動
- 中央 → `Escape` — いつでもキャンセル
- サイドボタン → `Ctrl+C` / `Ctrl+V` — 片手でコピペ
- サイドボタン → `Command+Space` — ワンクリックで Spotlight / 検索を起動

## 技術詳細

### Windows
- C + Win32 API、約 960 行
- `SetWindowsHookEx(WH_MOUSE_LL)` によるグローバルフック
- `SendInput` を非同期ワーカースレッドで実行（フックのタイムアウト回避）
- システムトレイアイコン + レジストリによるスタートアップ登録

### macOS
- Swift、約 500 行
- `CGEventTap` セッションレベルのイベントインターセプト
- 修飾キーのデュアルチャネル：IOKit（システムレベル） + CGEvent（アプリレベル）で、macOS の合成イベントフィルタリング問題を解決
- launchd によるスタートアップ登録

## ビルド

### Windows

GCC (MinGW-w64) が必要：

```bash
cd windows
build.bat
```

### macOS

Swift 5.9+ が必要：

```bash
swift build -c release
```

## License

MIT
