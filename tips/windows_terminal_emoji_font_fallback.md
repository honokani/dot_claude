# Windows Terminal: 絵文字表示のフォントフォールバック

## 問題
絵文字グリフを持たないフォント(Intel One Mono等)を使っていると絵文字が文字化けする。

## 解決
`settings.json` の font 設定に `fallback` を追加:

```json
"font": {
    "face": "Intel One Mono",
    "fallback": ["Segoe UI Emoji"],
    "features": { ... }
}
```

- `Segoe UI Emoji` はWindows標準搭載、追加インストール不要
- 元フォントの合字(liga, dlig, calt等)には影響しない
- Windows Terminalはsettings.jsonをホットリロードする
