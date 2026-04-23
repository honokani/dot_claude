# dot_claude 自動管理（auto_manage）

dot_claude の同期・セキュリティ自動化のための設計・実装プラン置き場。

## 目的
- **push忘れ防止**: ~/.claude/配下の変更を確実にpush
- **pull忘れ防止**: 他マシンの変更を漏れなく取り込み
- **機微情報漏洩防止**: API key/取引先名等がpushされる前に検出

## 構成
- [plan.md](plan.md) — Phase分けされた実装計画 + ファイル配置図
- [flow_diagram.md](flow_diagram.md) — 各処理フローのPFD精神に基づく箇条書き記述（記法は skills/pfd/SKILL.md 参照）
- [recovery.md](recovery.md) — 異常時の回収フロー（conflict/reject/機微情報検出）

## 状態
設計段階。実装は Phase 0.2.1 以降で段階的に着手予定。
