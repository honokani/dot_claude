# qcheck — PROGRESS.md

> 更新頻度：中（実装ステップごとに更新）

---

## 現在のフェーズ: **Phase 0.2.0 — SKILL.md + examples ドラフト完了、要レビュー**

テスト累計: **0 Green**

---

## フェーズ一覧

```
Phase 0.1.0: 設計記録                       ドラフト完了・要レビュー
Phase 0.2.0: SKILL.md + examples            ドラフト完了・要レビュー
Phase 1.0.0: 初運用（crawl_news で初実行）   未着手
Phase 1.1.0: 改善イテレーション              未着手
```

## Phase 0.1.0: 設計記録（ドラフト完了）
- [x] VISION.md
- [x] DECISIONS.md
- [x] PROGRESS.md（このファイル）

## Phase 0.2.0: SKILL.md + examples（ドラフト完了）
- [x] SKILL.md（TEMPLATE_SKILL.md準拠、frontmatter + ワークフロー）
- [x] examples/translate.qcheck.md（qcheck.md 入力フォーマット例）
- [x] examples/qcheck_result_sample.md（結果ファイルフォーマット例）

## Phase 1.0.0: 初運用（未着手）
- [ ] crawl_news/tests/translate.qcheck.md（title_ja の自然さ）
- [ ] crawl_news/tests/error_message.qcheck.md（エラー文言の統一性・わかりやすさ）
- [ ] crawl_news/tests/viewer_ui.qcheck.md（モノクロ化後の識別性）
- [ ] 初回実行（Claudeがスキル指示に従って Agent spawn → 結果書出）
- [ ] 結果レビューと観点修正

## Phase 1.1.0: 改善イテレーション（未着手）
- [ ] 判定精度のフィードバック取り込み
- [ ] context フォーマットの不明瞭点修正
- [ ] 判定ブレが大きい項目の多数決化検討（必要時のみ）

<!--
## 記法ルール
- Phase番号はセマンティックバージョニング準拠（初期構想完成=1.0.0）
- 完了: チェックリスト [x]
- 未完了: チェックリスト [ ]
- 決定ログ（何をしたか）はPhase内に自由記述可。判断根拠（なぜ）はDECISIONS.mdへ

## 設計上のメモ
- スキルは Python等のコード不要、SKILL.md の指示文を Claude が解釈して実行する形
- Phase 1.0.0 の「実装」は SKILL.md の指示が機能するか実環境で検証することを指す
-->


<!--
## 記法ルール
- Phase番号はセマンティックバージョニング準拠（初期構想完成=1.0.0）
- 完了: チェックリスト [x]
- 未完了: チェックリスト [ ]
- 決定ログ（何をしたか）はPhase内に自由記述可。判断根拠（なぜ）はDECISIONS.mdへ
-->
