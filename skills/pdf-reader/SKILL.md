---
name: pdf-reader
description: PDFファイルからテキストを抽出する。ユーザーが「PDFを読んで」「PDFの内容を確認」「このPDFを要約」と言ったとき、またはファイルパスが.pdfで終わるファイルを扱うときに使う。
compatibility: Windows (MINGW64/Git Bash)。uv venvに pymupdf インストール済み。
metadata:
  author: honokani
  version: 1.1.0
---

# PDF Reader

Windows環境でPDFのテキストを抽出するスキル。

## 環境

- venv: `~/.claude/workspace_for_claude/.venv/`
- 依存: pymupdf（venv内にインストール済み）
- グローバルpipは使わない

## 手順

### 全ページ抽出

```bash
~/.claude/workspace_for_claude/.venv/Scripts/python ~/.claude/skills/pdf-reader/scripts/read_pdf.py "PDFファイルのパス"
```

### ページ指定抽出

```bash
~/.claude/workspace_for_claude/.venv/Scripts/python ~/.claude/skills/pdf-reader/scripts/read_pdf.py "PDFファイルのパス" --pages "1-5"
~/.claude/workspace_for_claude/.venv/Scripts/python ~/.claude/skills/pdf-reader/scripts/read_pdf.py "PDFファイルのパス" --pages "1,3,7"
```

### PDF → PNG変換

全ページ:
```bash
~/.claude/workspace_for_claude/.venv/Scripts/python ~/.claude/skills/pdf-reader/scripts/pdf_to_png.py "PDFファイルのパス" --output "出力ディレクトリ"
```

ページ指定 + DPI指定:
```bash
~/.claude/workspace_for_claude/.venv/Scripts/python ~/.claude/skills/pdf-reader/scripts/pdf_to_png.py "PDFファイルのパス" --pages "1-5,10,22-23" --output "出力ディレクトリ" --dpi 200
```

オプション:
- `--pages` / `-p`: ページ指定（省略時は全ページ）
- `--output` / `-o`: 出力先ディレクトリ（省略時はPDFと同じ場所）
- `--dpi`: 解像度（デフォルト200）
- `--prefix`: ファイル名プレフィックス（デフォルトはPDFファイル名）

## 注意事項

- スクリプト内で `sys.stdout.reconfigure(encoding='utf-8')` を行っている（cp932エラー回避）
- 作業用の一時ファイルが必要な場合は `~/.claude/workspace_for_claude/` に置く
- 出力が大きい場合はページ範囲を指定して分割読み取りする

## トラブルシューティング

### venvが壊れた / pymupdfが見つからない
```bash
cd ~/.claude/workspace_for_claude && uv venv .venv && uv pip install pymupdf
```

### UnicodeEncodeError: 'cp932' codec can't encode character
原因: Windows環境のデフォルトエンコーディング問題
解決: スクリプトが自動で対処済み。直接Pythonを書く場合は `sys.stdout.reconfigure(encoding='utf-8')` を冒頭に入れる
