# dot_claude 自動管理 実装計画

## 要件

### 同期
- セッション開始時に dot_claude を最新化（pull --rebase --autostash）
- セッション終了時／commit時にpush漏れを警告（ahead N 検出）
- conflict/rejectは異常系として通知、手動解決へ誘導

### セキュリティ
- commit前に機微情報検出（gitleaks）
- デフォルトパターン（API key等）+ カスタムパターン（取引先名・社内コードネーム）
- **カスタムパターン設定ファイルは git管理対象外**（~/.claude/gitleaks/配下にローカル保管）
  - 理由: 取引先名リスト自体が機微情報。dot_claudeが公開されても漏れない設計

## Phase 分け

### Phase 0.2.0.自動管理基盤設計（本作業）
- auto_manage/ フォルダ設置
- 設計・計画ドキュメント作成（README/plan/flow_diagram/recovery）
- GLOBAL_PROGRESS.md / GLOBAL_DECISIONS.md に方針記録

### Phase 0.2.1.gitleaks pre-commit フック
- `dot_claude/.githooks/pre-commit` に gitleaks 呼び出しを配置
- `dot_claude/.gitleaks.toml`（公開可能な汎用ルール、API key等）
- `~/.claude/gitleaks/rules.toml`（取引先名等、ローカル専用・git対象外）
- `link_claude.sh` で `git config core.hooksPath .githooks` を実行
- dotfiles の initialize スクリプトに gitleaks インストール追加

### Phase 0.2.2.SessionStart pull 同期
- `scripts/hooks/session-start-pull.sh` 新設
- `settings.json` SessionStart に登録
- 成功時は無音、conflict/reject/detached は stdout 警告
- 通常は数百msで完了、体感差なし想定

### Phase 0.2.3.push忘れ警告
- SessionEnd or PreCompact で `git status -sb` → ahead N 検出
- stdout 警告で push を促す
- 既存の scripts/hooks/append-compact-summary.sh に統合 or 独立スクリプト

### Phase 0.2.4.dotfiles連携
- `dotfiles/initialize_ubuntu.2.sh` に dot_claude clone + link処理追加
- gitleaks インストールも同スクリプトで統合
- Mac/Linux/Windows で gitleaks を入手する方法を明記

## 未決事項

### Phase 0.2.2
- SessionStart pull の失敗時、Claude Code 起動自体をブロックするか（exit 1）、警告のみか
  - 現在案: **警告のみ**（exit 1 は不便）

### Phase 0.2.1
- gitleaks 誤検知時の bypass 手順
  - 案A: `--no-verify` で回避（ただし運用ルールで原則禁止）
  - 案B: allowlist 追加して再commit
- gitleaks のカスタムrule は誰が管理するか（ユーザー自身が ~/.claude/gitleaks/ を手動編集）

### 全体
- 複数マシン同時編集での GLOBAL_PROGRESS.md / GLOBAL_DECISIONS.md の conflict 多発リスク
  - 対策: pj管理ファイルは書き込み直前に必ず pull するルールを CLAUDE.md に追記
