# qcheck — VISION.md

## Why

翻訳の自然さ・UIの識別性・エラー文言のわかりやすさなど、unit test で縛れないファジーな観点を AI判定でゆるくテスト化する。`tests/*.qcheck.md` のチェックリストを sub-agent に判定させ、結果を `tests/qcheck_result.YYMMDD.md` に書き出す。

## 設計思想

### 全体指針

- [philosophy] スキルは runner 限定、qcheck.md の生成・編集は対話で都度行う — Why: 観点の妥当性は対話で詰める方が品質高く、自動生成はノイズ源になる
- [philosophy] 判定は Agent ツール経由でサブエージェントが行う — Why: Maxプラン内で完結し、API直叩きの課金や `uv run` 等の CLI 起動オーバーヘッドを発生させない
- [philosophy] 1回判定・落とさない（advisory） — Why: AI判定は非決定的で CI gate に不向き。緩く運用してフィードバックを人間に返す方が誤検知コストが低い
- [philosophy] qcheck.md は `tests/` 直下に置く — Why: unit test と同居で発見性が高く、テスト類のディレクトリ規約を一本化できる
- [philosophy] qcheck.md が不在の時はスキル起動せず対話モードへ誘導する — Why: 空振り防止。新規作成は対話で項目を詰めるフローへ自然に橋渡しする
