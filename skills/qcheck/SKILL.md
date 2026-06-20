---
name: qcheck
description: 「skillsのqcheckを使って品質チェックしたい」「qcheck回して」と言われた時に、`tests/*.qcheck.md` のチェックリストをサブエージェントで判定し、結果を `tests/qcheck_result.YYMMDDhhmiss.md` に書き出す。判定は1回・advisoryでテスト失敗にはしない。qcheck.md が不在のとき/作成依頼のときはスキル起動せず対話モードに入る
compatibility: OS非依存（Agent ツールが使える Claude Code 環境）
metadata:
  author: honokani
  version: 0.1.0
  source: dot_claude/skills/qcheck/VISION.md
---

# qcheck — Quality Check Runner

翻訳の自然さ・見た目の良さ・文言のわかりやすさなど、unit test で縛れないファジーな観点を AI判定でゆるくテスト化するスキル。`tests/*.qcheck.md` のチェックリスト項目を Agent ツール経由でサブエージェントに判定させ、pass/fail と一言理由を集約して結果ファイルに書き出す。

## 目的 / When to use

**起動する条件:**
- ユーザーが「qcheck回して」「品質チェックして」「skillsのqcheckで」等の依頼をした
- かつ `tests/*.qcheck.md` が1つ以上存在する

**起動しない条件:**
- `tests/*.qcheck.md` が存在しない → スキル起動せず「qcheck.md がまだありません。何の qcheck を作りますか?」と返して対話モードへ
- 「qcheck.md を作って」「○○に関する qcheck 作ろう」等の作成依頼 → スキル起動せず、対話で項目を詰めて `tests/<feature>.qcheck.md` に保存
- 「qcheckを使いたい。まずは○○.qcheck.md 作ろう」のような複合発話 → 直近の指示（作成）を優先、スキルは将来の起動意図として理解するが今は起動しない

## ワークフロー / Usage

1. `tests/*.qcheck.md` を全て発見する
2. 各ファイルをパース:
   - 先頭の `# <name>.qcheck.md` をファイル名/対象として記録
   - `## context` セクションがあれば判定材料の取得方法を読み取る（永続データ読込・コード実行による生成・source検索 等）
   - 無ければファイル名と check 項目から sub-agent が推測する
   - `## checks` セクションの `- [ ]` 各項目を抽出
3. context があればそれに従って判定材料を収集、無ければ sub-agent が推測して収集
4. 各 check 項目について Agent ツール（general-purpose）を spawn:
   - プロンプト例: 「以下のサンプルを見て、観点『<check文>』について **pass / fail** のいずれかを判定し、1行で理由を添えてください。」
   - サンプル本体 + check 文 + 判定形式の指示を渡す
5. 全項目の結果を集約
6. `tests/qcheck_result.YYMMDDhhmiss.md` に書き出す（`examples/qcheck_result_sample.md` 参照）
7. 完了報告：結果ファイルのパスと pass/fail のサマリを返す。**テスト失敗にはしない**

## 前提 / Prerequisites

- プロジェクトに `tests/` ディレクトリが存在すること
- `tests/*.qcheck.md` を最低1つ作成済みであること（不在時は起動せず対話誘導）
- Claude Code 環境（Agent ツール利用可能）

## qcheck.md フォーマット

```markdown
# <feature>.qcheck.md

## context  (省略可)
sample: <判定材料の取得方法>

## checks
- [ ] <観点1>
- [ ] <観点2>
- [ ] <観点3>
```

context を書く目安:
- サンプルを絞りたい（評価値>=3、最新N日分、件数制限など）
- 判定対象の取得が非自明（コード実行、source 検索など）
- 複数候補があって明示したい

省略時の挙動:
- sub-agent がファイル名と check 項目から判定材料を推測する
- 例: `translate.qcheck.md` + 「title_ja が原文の意味を保っているか」 → toml の title_ja を見に行く

sample の例（3パターン）:
- 永続データ読込: `newslog_auto/最新3日分 評価値ilv >= 3 の10件`
- コード実行による生成物: `viewer.py の render_index_html を呼び、最新3日分の HTML を取得`
- source検索: `src/ 内「失敗）」を含むエラー文字列を全件 grep`

詳細は `examples/translate.qcheck.md` を参照。

## 結果ファイルフォーマット

```markdown
# qcheck result — YYYY-MM-DD HH:MI:SS

## <feature>.qcheck.md
- [PASS] <観点> — <理由>
- [FAIL] <観点> — <理由>
```

詳細は `examples/qcheck_result_sample.md` を参照。

## 注意事項 / Caveats

- 判定は1回。同じ入力で結果がブレることがある（advisory扱いのため許容）
- テスト失敗にはしない。あくまで品質改善のためのフィードバック提供が目的
- context は省略可。書くなら具体的に（曖昧だと判定精度が落ちる）。省略時は sub-agent がファイル名と check 項目から推測する
- 大量サンプル × 多数項目は Agent spawning のコストと時間が嵩む。1ファイルあたり check は5項目以内、sample は10件以内を推奨
- 新規 qcheck.md の作成・編集はこのスキルの守備範囲外。対話モードで詰める
