---
name: mermaid-to-svg
description: Markdown 内の Mermaid 図を静的 SVG に変換してビューア表示負荷を削減する。ネスト subgraph・多ノードなどで重い Mermaid 図を含む .md ファイルで使用。Node.js 必須
---

# Mermaid → SVG 変換ワークフロー

Markdown 内の Mermaid コードブロックを事前レンダ済み SVG に置き換え、クライアント側の Mermaid パース・レイアウト計算を不要にする。

## 目的

- 重い Mermaid 図の表示負荷をゼロ化（静的 SVG は瞬時表示）
- 再生成可能な形でソースを保持（`.mmd`ファイル）
- 元 Markdown ファイルとの対応を命名で明示

## 前提

- Node.js がインストール済み（`node -v` で確認）
- `npx` 経由で `@mermaid-js/mermaid-cli` を都度実行（グローバルインストール不要）
- 初回 Puppeteer 取得に数分かかる。2 回目以降は数秒/図

## 配置規約

対象 `.md` ファイルと同じディレクトリに `diagrams/` サブフォルダを作成:

```
target_dir/
├── {source}.md                     ← 対象 Markdown
└── diagrams/
    ├── build.sh                    ← 再生成スクリプト
    ├── {source}_fig1.mmd           ← ソース（編集用）
    ├── {source}_fig1.svg           ← 生成物（表示用）
    ├── {source}_fig2.mmd
    ├── {source}_fig2.svg
    ...
```

**命名規則**: `{元ファイルstem}_fig{N}.{mmd|svg}`

元ファイルとの対応を明示することで、同一 `diagrams/` ディレクトリに複数 MD からの図が混在しても追跡可能。

## 手順

### 1. diagrams/ ディレクトリ作成

```bash
mkdir -p {対象ディレクトリ}/diagrams
```

### 2. Mermaid ブロックを .mmd に抽出

各 ` ```mermaid ... ``` ` ブロックの中身（フェンスを除く）を `{source_stem}_fig{N}.mmd` として保存。
出現順に N=1, 2, 3... を振る。

### 3. SVG 変換

個別変換:
```bash
npx -y @mermaid-js/mermaid-cli -i {name}.mmd -o {name}.svg
```

一括変換スクリプト（`diagrams/build.sh` として保存・`chmod +x`）:
```bash
#!/bin/bash
# Mermaid .mmd → .svg 一括変換スクリプト
set -e
cd "$(dirname "$0")"
for mmd in *.mmd; do
    svg="${mmd%.mmd}.svg"
    echo "Building: $mmd -> $svg"
    npx -y @mermaid-js/mermaid-cli -i "$mmd" -o "$svg"
done
```

### 4. Markdown 書き換え

` ```mermaid ... ``` ` ブロックを下記に置換:

```markdown
![図タイトル](diagrams/{source}_fig{N}.svg)

<!-- ソース: diagrams/{source}_fig{N}.mmd （再生成: `bash diagrams/build.sh`） -->
```

## Mermaid 構文の注意点（抽出時の落とし穴）

エッジラベル・ノードラベル内の特殊文字は Mermaid パーサの node-shape 記法と衝突する:

| 記号 | HTML エンティティ | 理由 |
|---|---|---|
| `{` `}` | `#123;` `#125;` | diamond-shape 記法と衝突 |
| `[` `]` | `#91;` `#93;` | rectangle-shape 記法と衝突 |
| `(` `)` | `#40;` `#41;` | round-shape 記法と衝突（ノードラベル内でも推奨） |

例（衝突回避）:
```
SetNode -.->|#123;0,1#125; ↪ #91;0,1#93;<br/>包含| Fuzzy
```

## 適用基準

以下のいずれかに該当したら適用を検討:

- ネスト subgraph を含む大型 Mermaid 図
- 1 ファイル内に 3 つ以上の Mermaid 図
- ビューア表示が重いと判明した時
- GitHub 以外のビューア（Mermaid 対応が弱い環境）で表示したい時

## 運用

- **図編集時**: `.mmd` を編集 → `bash diagrams/build.sh` で再生成
- **ソース保持**: 元 Mermaid コードは `.mmd` で保存（完全可逆）
- **命名**: 必ず `{元ファイルstem}_fig{N}` で元ファイルとの対応を保つ
- **Git 管理**: `.mmd`（ソース）と `.svg`（成果物）の両方をコミット

## トレードオフ

| 観点 | Mermaid 埋め込み | 静的 SVG |
|---|---|---|
| 表示速度 | 遅い（クライアント計算） | 速い（事前レンダ） |
| 編集反映 | 即時 | `build.sh` 実行必要 |
| ソース位置 | `.md` 内 | `.mmd` 別ファイル |
| 差分追跡 | テキスト diff | SVG テキスト diff（やや長い） |
| GitHub 表示 | 自動レンダ | 画像表示 |

重い図のみ静的化し、軽い図は埋め込みを残す選択肢もある。
