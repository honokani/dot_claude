# ~/.claude — GLOBAL_VISION.md

## Why
Claudeとの協働環境を、セッションをまたいで一貫性のある形で維持する。
「秘伝のタレ」として育ってきたCLAUDE.mdを中心に、指示・設計・進捗・判断を分離して管理する。

## 設計思想

### 全体指針
- [philosophy] CLAUDE.mdは「指示書」、GLOBAL_VISION.mdは「設計書」。混ぜない
- [philosophy] 自動化はフック層、判断はClaude、記録はファイル。責務を分離する
- [philosophy] 「無いときは無い」— 強制終了等でデータが欠損する前提で設計する
- [philosophy] CLAUDE.mdは「共通契約（全実行主体）」＋「対話セッション限定ルール」の2部構成。サブエージェント（Explore/Plan以外、モデル問わず）にも配布されるため、対話前提のルール（承認・提示・pj管理）は後半に隔離し、前半はどのモデルが読んでも成立する内容に限る
- [philosophy] 発動保証と手続き本体を分離する。CLAUDE.mdには発動トリガー（1〜2行）だけ置き、手続き本体はskill／参照ファイル（bulk-verification・pj-management・MODEL_ROUTING.md・MAINTENANCE.md）に置く。~/.claude保守ルールはdot_claude作業時のみ必要なので、`.claude/CLAUDE.md`のimport shim経由でそのセッションだけに読ませる

### 情報アーキテクチャ

#### pj管理3ファイル（各プロジェクトルートに配置）
| ファイル | 比喩 | 内容 | 更新頻度 |
|---|---|---|---|
| VISION.md | 設計図 | なぜそう作るか。思想・不変条件 | 低 |
| DECISIONS.md | 議事録 | なぜAでなくBか。確定判断の根拠 | 中 |
| PROGRESS.md | チェックリスト | 何が完了し、何が残っているか | 高 |

#### latest_cache（`~/.claude/project_info/` に配置）
- **比喩: レジスタダンプ** — compact/セッション終了時のCPUレジスタの内容
- **核はサマリー（会話内容）。** git状態は補助情報
- compact_summaryがある場合（PostCompact経由）はそのまま記録、無い場合（SessionEnd経由）はtranscript末尾から抽出
- 1セッション=1キャッシュファイル。既存マーカーがあればID再利用+追記（ログ孤立防止）

##### latest_cacheに書くもの
- 作業中の仮説（未検証、DECISIONS行きが確定していないもの）
- 直面中のエラーとその再現手順（解決済みならPROGRESSに移る）
- 「次にやること」の具体的な1手（PROGRESSの粒度より細かい）
- 比較中のファイル内容や中間結果（一時的で、完了後は不要になるもの）

##### latest_cacheに書かないもの
- 完了した作業 → PROGRESS
- 確定した判断 → DECISIONS
- git statusやdiff → 再取得可能

#### 鮮度判定ルール
- latest_cacheの更新日 ≥ max(VISION.md, DECISIONS.md, PROGRESS.mdの更新日) → 読む
- latest_cacheの更新日 < max(3ファイル) → 読まない（別セッションで更新済み）
- 読んでも読まなくてもold/に移動する

### ファイル管理の境界原則
- ~/.claudeはgit管理下にある
- `.gitignore`にあるもの = Claude Code本体が自動生成 = 管理外
- `.gitignore`にないもの = ユーザーが作成・管理
- `git ls-files`でユーザー管理ファイル一覧が取れる
- 未追跡ファイルを見つけたら報告する（勝手にgit addしない）

### ~/.claude グローバル管理
| ファイル | 役割 |
|---|---|
| CLAUDE.md | Claudeへの指示書（共通契約＋対話セッションのルール。全セッションに配布） |
| MAINTENANCE.md | ~/.claude自体の保守ルール（同期・GLOBAL_*記録・剪定・仕組みの所在）。dot_claude作業時は `.claude/CLAUDE.md`（`@../MAINTENANCE.md` import shim）で自動読込 |
| MODEL_ROUTING.md | サブエージェント委譲のモデル振り分け（手続き本体） |
| skills/pj-management/ | pj管理3ファイルの記録基準・タグ体系・テンプレート（手続き本体） |
| skills/TEMPLATE_SKILL.md | skill新設時のテンプレート |
| GLOBAL_VISION.md | ~/.claudeシステム自体の設計思想（本ファイル） |
| GLOBAL_PROGRESS.md | 設定変更ログ |
| GLOBAL_DECISIONS.md | 設定・運用の判断根拠ログ |
| link_claude.sh | dot_claude→~/.claude のsymlink設置＋壊れたリンクの掃除（冪等） |

### フック設計方針
- [philosophy] フックの責務は「機械的な記録と配置」のみ。判断はClaude、更新指示はCLAUDE.md
- [philosophy] フックは失敗しても本体動作をブロックしない（exit 0で終了）
- [philosophy] スクリプトは `~/.claude/scripts/hooks/` に配置（`.claude/hooks/`はClaude Code本体と混同リスク）

### セッション継続方針
- [philosophy] 主手段は `claude --continue`（会話履歴の完全復元）
- [philosophy] latest_cacheは「resumeもcontinueもしなかった場合」のフォールバック

### latest_cacheのライフサイクル
```
[PreCompact] ← フック（save-context-cache.sh）
  → 既存マーカー探索 → あればID再利用+追記、なければ新規作成
  → ~/.claude/project_info/latest_cache_{id}.log 作成or追記
  → $(pwd)/.claude/pjcache_marker_{id} 作成（0Bマーカー、新規時のみ）

[PostCompact] ← フック（append-compact-summary.sh）
  → compact_summaryをそのまま追記

[SessionStart] ← フック（session-start-cache.sh、0.2.14で全自動化を確認）
  → マーカー発見 → latest_cache発見 → 鮮度判定
  → 読む（stdout経由でコンテキストに注入）/読まない → old/{プロジェクト名}/ に移動 → マーカー削除
```
