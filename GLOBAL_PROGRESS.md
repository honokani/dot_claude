# GLOBAL_PROGRESS

CLAUDE.md および ~/.claude 配下の設定変更ログ。

## Phase: 0.0.1.基盤構築 (2026-03-10)
- [x] ~/.claude を git 管理下に置いた（ローカル専用、user: claude with honokani）
- [x] KEYWORDS.md のルール拡張 — インデックス専用化、3行フォーマット、KEYWORDS_ARCHIVE.md によるアーカイブ運用を定義
- [x] 割り込み作業とブランチ管理セクション追加 — git worktree 運用、stash 非推奨、中断スナップショット記録ルールを定義
- [x] GLOBAL_PROGRESS.md / GLOBAL_KEYWORDS.md 新設
- [x] workspace_for_claude セクション追加 — 作業ディレクトリ・venv(uv)・Rust利用ルール定義
- [x] Skills セクション追加 — `~/.claude/skills/<skill-name>/SKILL.md` 配置ルール定義
- [x] pdf-reader Skill 新設 — pymupdf による PDF テキスト抽出（venv内）
- [x] CLAUDE.md スリム化 — 124行→96行、情報量維持で冗長表現を圧縮
- [x] 行動原則修正 — 「謝罪禁止」→「過剰な謝罪禁止」に緩和

## Phase: 0.0.2.ツール整備 (2026-03-16〜17)
- [x] Windows Terminal 絵文字フォールバック設定 (Intel One Mono + Segoe UI Emoji)
- [x] tools/session-viewer プロジェクト開始 — セッション検索(VectorDB)+閲覧(Webビューア)ツール、設計完了
- [x] session-viewer 初期実装完了 — VectorDB検索, Webビューア(markdown描画), Haiku要約, プロジェクトフィルタ
- [x] /recall Skill追加 — 過去会話のベクトル検索
- [x] VISION.mdをポールスター型に再定義 — 実装詳細排除、Why・思想・トレードオフ・散在一覧に限定。TEMPLATE_VISION.md新設

## Phase: 0.0.3.体系再編 (2026-03-20)
- [x] VISION.md設計思想を3層構造化 — 全体指針/機能横断ルール/機能別指針。[philosophy]/[tested]タグ導入
- [x] KEYWORDS.md廃止→DECISIONS.mdに移行 — 判断根拠ログとして独立ファイル化、TEMPLATE_DECISIONS.md新設
- [x] GLOBAL_KEYWORDS.md廃止→GLOBAL_DECISIONS.mdに変換
- [x] TEMPLATE_VISION.mdからトレードオフログセクション削除（DECISIONS.mdに分離）
- [x] コーディングスタイル拡充 — 言語横断関数型明示、Python向けルール追加、`uv run python`強制、デバッグ手法をコーディングスタイルに統合
- [x] 変更管理にメモ化ルール追加、設計判断に仕様式全項実装ルール追加
- [x] workspace_for_claude簡素化（venv/Rust言及削除）、Skills・tipsの重複記述整理
- [x] GLOBAL_DECISIONS.mdにPhaseカラム導入、全エントリにPhase割り当て
- [x] Phase番号にセマンティックバージョニング準拠ルールを明文化（初期構想完成=1.0.0）

## Phase: 0.0.4.フック導入 (2026-03-21〜23)
- [x] コンテキスト退避フック導入 — compact/セッション終了前にlatest_cache生成 + マーカー配置（save-context-cache.sh）
- [x] compactサマリーフック導入 — compact summaryをlatest_cacheに追記（append-compact-summary.sh）※後にフック解除
- [x] SessionStartフック導入 — マーカー探索→鮮度判定→コンテキスト注入→old/移動（session-start.sh）※後にフック解除
- [x] GLOBAL_VISION.md新設 — ~/.claudeシステムの設計思想（情報アーキテクチャ、フック方針）
- [x] CLAUDE.mdにlatest_cache操作手順追加
- [x] CLAUDE.md「~/.claudeの変更管理」からGLOBAL_VISION.md参照に変更
- [x] 旧compact-snapshots方式を廃止、project_info方式に移行
- [x] マーカー配置先を `$(pwd)/.claude/pjcache_marker_{id}` に決定（.gitignore追加不要）
- [x] latest_cache鮮度判定ロジック実装 — max(VISION/DECISIONS/PROGRESS更新日) vs cache更新日
- [x] `set -e`下でのls失敗問題を修正（`|| true`ガード）
- [x] テストスイート作成 — `scripts/test/hooks/test_compact_hooks.sh`（6ケース21アサーション、全パス）
- [x] GLOBAL_VISION.mdに「ファイル管理の境界原則」追加 — .gitignoreを本体/ユーザーの境界線として明文化
- [x] 「開発管理」→「pj管理」リネーム — 全5ファイル22箇所一括置換
- [x] TEMPLATE_PROGRESS.md新設 — pj管理3ファイルのテンプレート完備
- [x] フック体系整理 — スクリプトリネーム（pre-compact→save-context-cache, post-compact→append-compact-summary）、SessionEnd追加、PostCompact/SessionStartフック解除（CLAUDE.md規約でClaude主導に移行）
- [x] save-context-cache.shにduration_ms計測追加 — フロントマターに実行時間記録
- [x] PostCompactフック復活 — compact_summary取得はフックでしか不可。CLAUDE.md規約では代替できない誤判断を修正
- [x] SessionEndにもappend-compact-summary.sh追加 — compact_summaryが無い場合はtranscript末尾から会話抽出。サマリーこそが機能の核
- [x] append-compact-summary.sh改修 — PostCompact/SessionEnd両対応。compact_summary優先、fallbackでtranscript_pathからuser/assistantテキスト抽出（末尾30行）
- [x] save-context-cache.sh改修 — 既存マーカーがあればID再利用+追記。/compact→/compact や /compact→/exit で1回目のログが孤立しない
- [x] CLAUDE.md latest_cacheセクション修正 — old/移動先を`old/{プロジェクト名}/`に修正（GLOBAL_VISION.mdと整合）
- [x] 「無いときは無い」の適用範囲をDECISIONSに明文化 — 強制終了時のみ、正常終了は含まない
- [x] SessionEndフック解除 — `--continue`常用により不要化。スクリプトは残置
- [x] セッション継続方針決定 — `claude --continue`をデフォルト運用、latest_cacheはフォールバックに格下げ
- [ ] compact→compact時の二重圧縮劣化問題 — compactが重なると初期文脈が劣化する（`--continue`常用で影響は軽微）
- [ ] ツール呼び出しカウント→compact提案フック検討
- [ ] /learnコマンド検討 — セッションからパターン半自動抽出→skills/learned/
- [ ] フック重要度モード検討 — minimal/standard/strict切り替え

### 調査メモ: everything-claude-code (affaan-m) からのいいとこ取り候補
- 出典: https://github.com/affaan-m/everything-claude-code
- 9割はフレームワーク別ボイラープレート。有用なのはフック層に集中
- 採用候補5件を上記チェックリストに反映済み
- スキップ: 言語別エージェント28種、116スキル大半、エンタープライズ系フック、"instinct"システム（過剰設計）

## Phase: 0.0.5.命名整理 (2026-04-17)
- [x] DESIGN.md → VISION.md グローバル改名 — UI文脈の"Design System"との混同を回避
  - [x] CLAUDE.md内の参照書き換え（pj管理セクション、latest_cacheセクション、~/.claude変更管理セクション）
  - [x] TEMPLATE_DESIGN.md → TEMPLATE_VISION.md（mvリネーム + 内部参照書換）
  - [x] GLOBAL_DESIGN.md → GLOBAL_VISION.md（mvリネーム + 内部参照書換）
  - [x] GLOBAL_DECISIONS.md / GLOBAL_PROGRESS.md 内の参照書換 + Phase 0.0.5判断/作業ログ追加
  - [x] scripts/hooks/session-start.sh のロジック書換（VISION.md mtime参照に変更、コメントも追従）
  - [x] scripts/test/hooks/test_compact_hooks.sh のテストデータ書換
- [ ] 既存6プロジェクトのDESIGN.md → VISION.md改名（pj_vibecoding, pj_zenech, pj-task-control-hub, 他3件）
