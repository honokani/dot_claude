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
- [x] DESIGN.mdをポールスター型に再定義 — 実装詳細排除、Why・思想・トレードオフ・散在一覧に限定。TEMPLATE_DESIGN.md新設

## Phase: 0.0.3.体系再編 (2026-03-20)
- [x] DESIGN.md設計思想を3層構造化 — 全体指針/機能横断ルール/機能別指針。[philosophy]/[tested]タグ導入
- [x] KEYWORDS.md廃止→DECISIONS.mdに移行 — 判断根拠ログとして独立ファイル化、TEMPLATE_DECISIONS.md新設
- [x] GLOBAL_KEYWORDS.md廃止→GLOBAL_DECISIONS.mdに変換
- [x] TEMPLATE_DESIGN.mdからトレードオフログセクション削除（DECISIONS.mdに分離）
- [x] コーディングスタイル拡充 — 言語横断関数型明示、Python向けルール追加、`uv run python`強制、デバッグ手法をコーディングスタイルに統合
- [x] 変更管理にメモ化ルール追加、設計判断に仕様式全項実装ルール追加
- [x] workspace_for_claude簡素化（venv/Rust言及削除）、Skills・tipsの重複記述整理
- [x] GLOBAL_DECISIONS.mdにPhaseカラム導入、全エントリにPhase割り当て
- [x] Phase番号にセマンティックバージョニング準拠ルールを明文化（初期構想完成=1.0.0）
