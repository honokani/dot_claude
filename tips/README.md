# tips 命名規則

プロジェクト横断の技術知見を置く。ファイル名は以下の規則に従う。

## 命名規則

```
<主題>_<細目>_<環境>.md
```

- **主題**: 中心となる言語・アプリ・ツール名
  - 例: `python`, `rust`, `ssh`, `windows-terminal`
  - 固有名詞で複数単語の場合は `-`（ハイフン）で連結
- **細目**: 扱う具体トピック
  - 例: `uv`, `http-server`, `emoji-font-fallback`, `non-interactive-path`
  - 複数単語は `-` で連結
- **環境**: OS/文脈（省略可）
  - 例: `windows`, `mac`, `linux`, `wsl`
  - 環境非依存なら省略

## 区切り文字のルール

- 要素区切り: `_`（アンダースコア）
- 単語内連結: `-`（ハイフン）
- **使い分けの意図**: `_` は意味的な要素区切り、`-` は1単語の構成要素
- `windows-terminal` = 1主題（Windows Terminal アプリ）
- `windows_terminal` = 2要素（windows環境 + terminal全般）と区別可能

## 例

| ファイル名 | 主題 | 細目 | 環境 |
|---|---|---|---|
| `python_uv_windows.md` | python | uv | windows |
| `python_http-server_windows.md` | python | http-server | windows |
| `windows-terminal_emoji-font-fallback.md` | windows-terminal | emoji-font-fallback | (省略) |
| `ssh_non-interactive-path.md` | ssh | non-interactive-path | (省略) |
| `math_textbook_authoring.md` | math | textbook, authoring | (省略) |
| `large_document_management.md` | document | large_management | (省略) |

## 追加ルール

- 新規追加時は既存ファイル名を参考に統一感を保つ
- 判断に迷ったら: 主題を先頭、環境を末尾
- 内容の最上部に `# <タイトル>` を書いて「このファイルは何か」を明示する
- 環境非依存なら `<主題>_<細目>.md` で2要素に省略可
