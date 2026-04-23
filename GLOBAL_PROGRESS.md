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

## Phase: 0.0.6.管理対象整理 (2026-04-22)
- [x] 未追跡skill/tips/plansをgit管理化（blog-crawler, mermaid-to-svg, slide-writing, pdf-reader/scripts/pdf_to_png.py, tips/*.md, plans/, TEMPLATE_PROGRESS.md）
- [x] .gitignore拡張
  - セッション自動生成物: paste-cache/, sessions/, session-env/, project_info/, tasks/, telemetry/
  - Skill別参考資料・キャッシュ: skills/*/reference/, skills/*/__pycache__/
  - バイナリ・キャッシュ: *.pptx, *.pdf, *.pyc, __pycache__/
  - シンボリックリンク実体: skills/recall/（session-viewer参照）, tools/session-viewer

## Phase: 0.1.0.dot_claude単独化 (2026-04-22)
- [x] ~/.claude/.git を /c/git_clone/dot_claude/.git に履歴保持でclone（ローカルclone → remote切替push）
- [x] GitHub honokani/dot_claude (private) に初回push
- [x] link_claude.sh 新設（dotfilesのlink_dotfiles.shと同系統。dot_claude配下のトップレベル項目を~/.claude/に個別リンク）
- [x] .gitattributes 追加（LF強制、dotfilesと同規約）
- [x] CLAUDE_candidate.md / CLAUDE_study.md 削除（別案件用のため配置不要）
- [x] ~/.claude/.git は保険として凍結（今後commit/pushしない、現役リポジトリは /c/git_clone/dot_claude/ に一本化）

## Phase: 0.1.1.link_claude.sh冪等性対応 (2026-04-22)
- [x] readlink で既存symlinkを検査、正しければスキップ（冪等）
- [x] _bk 連番対応（_bk, _bk1, _bk2...）で既存バックアップ保護
- [x] ln -sn で既存ディレクトリへの副作用リンク作成を防止（skills/skills誤リンク対策）
- [x] mv/ln 失敗時に ERROR 出力 + return 1、exit statusで伝播
- [x] ~/.claude/skills/skills 誤リンク削除（初回実行の副作用クリーンアップ）
- [ ] Claude Code 終了後に link_claude.sh 手動実行で skills/ リンク化完了（ユーザー側作業）
- [ ] 動作確認後、~/.claude/*_bk（CLAUDE.md_bk, GLOBAL_*_bk, plans_bk, scripts_bk, settings.json_bk, skills_bk, TEMPLATE_*_bk, tips_bk）を削除

## Phase: 0.1.2.plans対象外化 (2026-04-22)
- [x] ~/.claude/plans シンボリックリンクを削除、dot_claude/plans/ 内容を ~/.claude/plans/ にcpで実ディレクトリ復元
- [x] dot_claude から plans/ を git rm -r（リポジトリからも実体からも削除）
- [x] .gitignore に plans/ 追加（プロジェクト寄りカテゴリ新設）

## Phase: 0.2.0.自動管理基盤設計 (2026-04-23)
- [x] auto_manage/ フォルダ新設（dot_claude同期・セキュリティ自動化の設計置き場）
- [x] 設計ドキュメント作成（README.md / plan.md / flow_diagram.md / recovery.md）
- [x] flow_diagram.md にPFD精神の箇条書きフローを併記（タスクとオブジェクトの分離）
- [x] GLOBAL_DECISIONS.md に自動管理の方針記録
- [x] skills/pfd/SKILL.md に「設計思想（Why）」「オブジェクトの具体性」節を追加（関数的composability原則を明記、抽象名vs実体名の対比表）
- [x] flow_diagram.md のPFD箇条書きを関数的フロー（◯=オブジェクト実体 → [ ]=タスク関数 → ◯ の交互連鎖）で全面書き直し
- [x] flow_diagram.md を PFDフロー箇条書き専用ファイルに整理（素のmermaid削除、記法解説はSKILL.mdに一元化）
- [x] ファイル配置図を plan.md に移動（静的関係は設計ドキュメント側に集約）
- [x] README.md の構成説明を更新
- [x] SKILL.md を形式中立に拡張（drawio/mermaid/箇条書き 3形式をサポート、使用要素表に記法列追加、mermaid実装メモ追加）
- [x] 「フローを描いて」= PFD 前提のルールを冒頭に明記
- [x] flow_diagram.md を PFD 準拠の mermaid 版に置換（オブジェクト=丸、タスク=四角、色分け、交互連鎖、補助入力を点線）

## Phase: 0.2.1.gitleaks pre-commit (2026-04-23)
- [x] gitleaks 8.30.1 を scoop で導入（`scoop install gitleaks`）
- [x] dot_claude/.githooks/pre-commit 新設（gitleaks git --staged、検出時 exit 1）
- [x] dot_claude/.gitleaks.toml 新設（デフォルトルール extend + ドキュメント内例示を allowlist で除外）
- [x] ~/.claude/gitleaks/README.md 新設（ローカルルール配置ガイド、git対象外）
- [x] .gitignore に gitleaks/ 追加
- [x] link_claude.sh に core.hooksPath 設定を追加
- [x] 動作確認: 高エントロピー文字列（ghp_*, AKIA*）および RSA PRIVATE KEY で commit ブロックを確認
- [ ] ~/.claude/gitleaks/rules.toml 配置（必要時にユーザー自身が作成）

## Phase: 0.2.3.SessionEnd auto-push（実験） (2026-04-23)
- [x] scripts/hooks/session-end-push.sh 新設（ahead検出 → git push、失敗時 stdout 警告）
- [x] settings.json SessionEnd hook 登録（timeout 30）
- [ ] 運用検証: セッション終了時に未push commit が自動 push される動作を次セッション以降で確認

## Phase: 0.2.2.SessionStart pull 同期 (2026-04-23)
- [x] scripts/hooks/session-start.sh → session-start-cache.sh にrename（latest_cache処理であることを名前で明示）
- [x] scripts/hooks/session-start-pull.sh 新設（git pull --rebase --autostash、up-to-date時無音、更新取込時/失敗時はstdout通知）
- [x] settings.json SessionStart hook 登録（pull → cache の順で実行、timeout 30）
- [ ] 運用検証: 次セッション以降で pull が発火、remote変更を自動取込、conflict時はwarning表示されることを確認

### 補足修正: hook script の REPO パス解決 (2026-04-23)
- [x] 問題発覚: `$HOME/git_clone/dot_claude` ハードコードが Windows環境（実体 `/c/git_clone/dot_claude`）で存在せず、hook が silent に exit 0 していた
- [x] session-start-pull.sh / session-end-push.sh: `$HOME/.claude/CLAUDE.md` symlink から readlink で dot_claude repo を動的解決（OS/配置非依存化）
- [x] 動作確認: session-end-push.sh 直接実行で ahead=1 検出 → `71c7a9c`（Phase 0.2.2）を hook 経由で auto-push 成功
- [ ] Phase 0.2.1: gitleaks pre-commit フック実装（カスタムruleはローカル保管）
- [ ] Phase 0.2.2: SessionStart pull 同期フック（conflict時stdout警告）
- [ ] Phase 0.2.3: push忘れ警告（SessionEnd/PreCompactでahead検出）
- [ ] Phase 0.2.4: dotfiles連携（initialize_ubuntu.2.shにdot_claude clone+link+gitleaks追加）
