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
- [x] テストスイート作成 — `scripts/test/hooks/test_compact_hooks.sh`(6ケース21アサーション、全パス)
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

## Phase: 0.2.2.SessionStart pull 同期 (2026-04-23)
- [x] scripts/hooks/session-start.sh → session-start-cache.sh にrename（latest_cache処理であることを名前で明示）
- [x] scripts/hooks/session-start-pull.sh 新設(git pull --rebase --autostash、up-to-date時無音、更新取込時/失敗時はstdout通知)
- [x] settings.json SessionStart hook 登録（pull → cache の順で実行、timeout 30）
- [x] 運用検証完了（2026-04-23）: 新セッション起動時に session-start-pull.sh が発火、HEAD変化なしで無音終了することを確認（grep文言依存バグはHEAD比較に置換して修正済み）

## Phase: 0.2.3.SessionEnd auto-push（実験） (2026-04-23)
- [x] scripts/hooks/session-end-push.sh 新設（ahead検出 → git push、失敗時 stdout 警告）
- [x] settings.json SessionEnd hook 登録（timeout 30）
- [x] 運用検証完了（2026-04-23）: /exit 時に SessionEnd hook 発火、ahead=2 検出 → `git push` で `60e4835` + `b5d12b6` を一括push成功。GitHub web UI でも反映確認済み

## Phase: 0.2.5.tips命名規則整備 (2026-04-23)
- [x] tips/README.md 新設（`<主題>_<細目>_<環境>.md` 形式、`_`/`-` 使い分け明記）
- [x] CLAUDE.md tips記録セクションに README 参照を追加
- [x] 既存tips のrename（参照箇所は Grep で事前確認、ゼロ件のため影響なし）:
  - python_windows_http_server.md → python_http-server_windows.md（環境を末尾に統一）
  - windows_terminal_emoji_font_fallback.md → windows-terminal_emoji-font-fallback.md（Windows Terminal を固有名詞として `-` 連結）
- [x] tips/ssh_non-interactive-path.md を git 追跡開始（`_` → `-` リネーム + add）
- [ ] rust_*.md 系も命名規則適合か後日レビュー（rust_howtodebug.md は `rust_how-to-debug.md` 相当）

### 補足修正: hook script の REPO パス解決 (2026-04-23)
- [x] 問題発覚: `$HOME/git_clone/dot_claude` ハードコードが Windows環境（実体 `/c/git_clone/dot_claude`）で存在せず、hook が silent に exit 0 していた
- [x] session-start-pull.sh / session-end-push.sh: `$HOME/.claude/CLAUDE.md` symlink から readlink で dot_claude repo を動的解決（OS/配置非依存化）
- [x] 動作確認: session-end-push.sh 直接実行で ahead=1 検出 → `a3aed36`（Phase 0.2.2）を hook 経由で auto-push 成功
- [ ] Phase 0.2.1: gitleaks pre-commit フック実装（カスタムruleはローカル保管）
- [ ] Phase 0.2.2: SessionStart pull 同期フック（conflict時stdout警告）
- [ ] Phase 0.2.3: push忘れ警告（SessionEnd/PreCompactでahead検出）
- [ ] Phase 0.2.4: dotfiles連携（initialize_ubuntu.2.shにdot_claude clone+link+gitleaks追加）

## Phase: 0.2.6.同期運用ルールの明文化 (2026-04-23)
- [x] CLAUDE.md に「複数環境ファイルの同期運用」セクション追加（編集前pull / 編集後push / auto-pushは失敗防止ネット）
- [x] memory に feedback_multi_env_sync.md 追加（将来セッションで手動push省略を防ぐ）
- [x] GLOBAL_DECISIONS.md に運用方針の判断を記録

## Phase: 0.2.7.機能単位ディレクトリ化（features/auto_manage/再編） (2026-04-23)
- [x] auto_manage/ を features/auto_manage/ に git mv
- [x] 実装実体を features/auto_manage/output/ 配下に集約:
  - .githooks/pre-commit
  - .gitleaks.toml
  - scripts/hooks/session-start-pull.sh
  - scripts/hooks/session-end-push.sh
- [x] dot_claude本体から output 内実体へ relative symlink を張る（機能の物理完結 + 既存パスへの後方互換）
- [x] パス参照を一括更新:
  - .gitleaks.toml allowlist: `auto_manage/*` → `features/auto_manage/*`
  - hook scripts (pre-commit, session-start-pull.sh, session-end-push.sh) コメント・エラーメッセージ
  - flow_diagram.md: `../skills/pfd/SKILL.md` → `../../skills/pfd/SKILL.md`（階層変化）
  - plan.md 自己参照更新

## Phase: 0.2.8.blog-crawler削除 (2026-04-23)
- [x] skills/blog-crawler/ を git と working tree から完全削除
- [x] 理由: 使用実績なし + WebFetchによるブログクロールは公開リポジトリで配布するには行儀が悪い（スクレイピング負荷・規約リスク）
- 注: Phase 0.0.6 履歴記述（git管理化した時の列挙）は事実として残置

## Phase: 0.2.9.rust tips rename + TEMPLATE_SKILL新設 (2026-04-23)

### tips命名規則適用（rust系）
- [x] rust_const_design.md → rust_const-design.md（const-design を1細目化）
- [x] rust_effect_system.md → rust_effect-system.md（effect-system を1細目化）
- [x] rust_howtodebug.md → rust_how-to-debug.md（単語連結を - で分離）
- 確認のみ変更不要: rust_egui.md / rust_serde.md / rust_windows.md

### SKILL.md フォーマット統一
- [x] TEMPLATE_SKILL.md 新設（frontmatter + 標準セクション、既存3 skillの共通形式を踏襲）
- [x] skills/pfd/SKILL.md に frontmatter追加（name, description, metadata）
- [x] CLAUDE.md Skills セクションに TEMPLATE_SKILL.md 参照を追加
- 今後の余地: 現フォーマットがベストか未検証。必要時レビューで改訂可能

## Phase: 0.2.10.`~/.claude/.git`凍結方針を終了・削除 (2026-04-23)
- [x] ~/.claude/.git を削除（Phase 0.1.0 の凍結方針を終了）
- 経緯:
  - Phase 0.1.0 で「保険として凍結・削除しない」と決定
  - その後 Phase 0.2.x で symlink化・features/ 再編を実施、~/.claude/.git 側には一切反映されず整合性が崩れ状態（working diff 39件の偽差分）
  - 最終commit `5ab47eb`（Phase 0.0.6）は dot_claude 側にも保持済で独自履歴ゼロ
- 現役リポジトリを /c/git_clone/dot_claude/.git に一本化

## Phase: 0.2.11.PROGRESS/DECISIONS 記録基準の明文化 (2026-04-24)
- [x] CLAUDE.md pj管理セクションに PROGRESS.md / DECISIONS.md の記録対象/対象外を追記:
  - PROGRESS 対象: 事前予定の進捗 + 既存挙動を変える/破壊する改修
  - PROGRESS 対象外: typo・即興の小変更（gitで追える）
  - DECISIONS 対象: A/B根拠 + 疑問に思われそうな実装の理由
  - DECISIONS 対象外: 一意に決まる作業・typo
- [x] ~/.claude の変更管理セクションを「pj管理と同一基準」の参照形式に更新
- 背景: 他プロジェクトで skills/slide-writing 改修時に「記録すべきか？」で混乱した経験を受けて明文化

## Phase: 0.2.12.bulk-verification skill 新設 (2026-05-16)
- [x] `skills/bulk-verification/SKILL.md` 新設 — 「全件」「全X」「全項目」等の bulk verification 依頼を受けた時に invoke する skill。項目単位サブエージェント並列化で観測可能性を確保し、メインの自力全件比較による虚偽完了報告を構造的に防止する
- [x] CLAUDE.md 行動原則に hard trigger 追加 — 「bulk 系依頼を受けた時点で自力処理に入る前に必ず `bulk-verification` skill を invoke」（skill 単独では発動漏れの可能性があるため、CLAUDE.md で発動保証）
- 背景: vibecoding-bootcamp 第2回 session2 同期作業で当方が3ラウンドにわたり「全件チェック完了」と虚偽報告した事案を受け、形質矯正のため当方の意志に依存しない構造を導入

## Phase: 0.2.13.CLAUDE.candidate.md 新設（剪定・圧縮・タグ体系改定） (2026-06-10)
- [x] CLAUDE.candidate.md を repo 直下に新設（採用待ちドラフト。採用 = CLAUDE.md と置換）
  - 旧モデル対応の禁止形表現を剪定: 推測回答禁止／おべっか・口答え禁止 等 → 判断基準・正形（検証根拠の添付、異議の事前提示等）へ書換
  - bulk-verification trigger は残置、根拠文言のみ書換（0.2.12 の実証事案 = 直近で再現した失敗のため剪定対象外）
  - 作業ステップ2を委譲拡大: 可逆×指示範囲内は実行→報告、不可逆・スコープ変更・設計判断は承認後（※意味変更。採用時に要判断）
  - ルールタグ改定: `[testable]` 廃止 → `[unittest]`/`[qchecktest]` 直接付与
  - タグ更新規則新設: テスト未作成は理由で分岐（思想由来→`[philosophy]`降格／未実装→タグ据置）
  - 同期運用に dot_claude 実体パス・symlink 構成を明記
  - 行数 118→107（既存内容の圧縮▲20行相当＋新規仕様+9行）
- [x] ~/.claude/CLAUDE.candidate.md（v1 仮置き）を repo 側へ一本化（rm deny によりClaude側から削除不可のためポインタ文書化。手動削除可）
- [x] ユーザーレビュー → 採用（2026-06-10）: CLAUDE.md を候補版（0.2.14反映後・100行）で置換、CLAUDE.candidate.md 削除
  - 採用前に滞留変更を確定コミット（CLAUDE.md改稿・テンプレ整形・settings.json。候補の基底を履歴に固定）
  - TEMPLATE_VISION.md のタグ表記を新体系へ整合（[tested]→[unittest]/[qchecktest]、qcheck例を1行追加）
  - 意味変更3点の判断根拠を GLOBAL_DECISIONS へ追記（表現方針／委譲境界／検証の位置づけ）

## Phase: 0.2.14.運用棚卸し: latest_cache/tips/トピックマーカー (2026-06-10)
- [x] latest_cache 実態調査 → **正常稼働を確認**（old/ に7プロジェクト分の消費実績、直近 2026-06-10 07:34 reflect_color）。「動いていない感」の正体は hook 全自動化による不可視性
  - session-start-cache.sh が探索→鮮度判定→注入→old/移動まで全自動実施しており、CLAUDE.md の手動手順は完全二重（Claude側は常に空振り）だった
  - CLAUDE.candidate.md の手動手順を削除し「hook全自動＋注入ブロックの扱い」へ置換（6行→3行）
- [x] tips 実態調査 → 生産側は稼働、**参照側が死亡**と判定
  - 実証: 本セッションで Claude が tips 記載済みの罠（BashツールへのPowerShell構文入力）を tips 未参照のまま再踏み（tips/bash_powershell-invocation_windows.md に解決策が既存）
  - CLAUDE.candidate.md に参照トリガー行を追加（環境・ツール系の躓き時、修正前に tips/ をgrep）
  - 未追跡だった tips/bash_powershell-invocation_windows.md（5/19作成、3週間同期ネット外）を git 追跡開始
- [x] トピックマーカー → **剪定**（候補版から削除。0.2.13剪定プロトコルの適用第1号）
  - 根拠: GLOBAL_DECISIONSに導入判断の記録なし／現行pj・GLOBALのDECISIONSに使用実績なし／検索目的はDECISIONS.mdの大分類/小分類列で代替済み／ユーザー証言「運用されていない古い取り決め」

## Phase: 0.2.15.シェル構文をbash固定 (2026-06-10)
- [x] CLAUDE.md コーディングスタイルに追加: シェルは常にbash/POSIX構文、PowerShell必須時のみ `powershell -File` 経由（ユーザー決定: git bash/zshが全環境に存在）
  - 背景: 新CLAUDE.md初回セッション冒頭で環境表記（Shell: PowerShell）由来の躓き3件（PowerShell構文→exit 127／python直打ち／MSYS2パス形式）。うち1件はtips既知の罠の再踏みで、0.2.14で仕込んだtips参照トリガーは不発（観測1回目）
- [x] tips 2件に知見追記（bash_powershell-invocation_windows.md「実体はbash」前提節／python_uv_windows.md パス形式節）— `3daed13`

## Phase: 0.2.16.tips参照のハーネス層昇格 (2026-06-10)
- [x] scripts/hooks/post-bash-tips-pointer.sh 新設 — Bash失敗時、環境系エラーシグネチャ該当ならtipsポインタ（ファイル名+見出しのみ、数十トークン）を additionalContext 注入。本文はClaudeがRead判断（段階的開示）
- [x] settings.json に PostToolUse / PostToolUseFailure（matcher: Bash, timeout 10）両登録 — 成功/失敗イベントは排他のため二重注入なし
- [x] ユニットテスト6ケースGreen: 成功時無音／exit 127→bashポインタ／FileNotFoundError→python_uvポインタ／pytest失敗（作業系）無音／文字列tool_response対応／tool_response欠落無音
- [ ] 実地検証（次セッション以降）: 環境系エラー時に [tips-hint] が実際に注入されるか／注入後に修正前Readが起きるか／PostToolUseFailure側の additionalContext サポート（公式docs未明記）

## Phase: 0.2.17.traps/tips分離 (2026-06-10)
- [x] traps/ 新設＋エラー系7本を移植（bash_powershell-invocation_windows, python_uv_windows, python_http-server_windows, ssh_non-interactive-path, rust_windows, rust_serde, rust_perf-patterns※未追跡だったため内容確認のうえ追跡開始）。~/.claude/traps symlink 作成
- [x] hook rename: post-bash-tips-pointer.sh → post-bash-traps-pointer.sh（向き先 traps/、[traps-hint]）。settings.json 参照更新
- [x] 照合強化: シグネチャ追加（panicked at / error[E番号] / cannot borrow / os error / アクセスが拒否 / Command timed out）／単語境界→部分一致（serde_json 等の連結識別子対応）／cargo・rustc→rust エイリアス／見出しのファイル名重複除去
- [x] ユニットテスト10ケースGreen（旧6 + cargo panic / exe lock / timeout / serde E0277）
- [x] traps/README.md 新設(記録基準=エラー観測可能性、ファイル名=照合キー)
- [x] CLAUDE.md tips記録節 → traps/tips 分離構成へ改訂（自発grepトリガー行は hook注入応答へ置換）
- [x] tips残留8本=非エラー知見（rust_egui・rust_const-design・rust_effect-system・rust_how-to-debug・windows-terminal_emoji-font-fallback・large_document_management・machine-learning_*・math_textbook_authoring）。扱い検討は継続

## Phase: 0.2.18.削除系コマンドの多層防御 (2026-04-24)
- [x] permission deny を Bash削除系で拡張: rmdir, unlink, find -delete, xargs rm, shred 等
- [x] PreToolUse hook 新設（features/auto_manage/output/scripts/hooks/pre-tool-block-delete.sh）:
  - bash/powershell 問わず tool_input.command を regex検査して削除系を exit 1 でブロック
  - 直接系: rm/rmdir/unlink/del/erase/Remove-Item/rd/ri/shred
  - 間接系: find -delete / xargs rm
- [x] settings.json PreToolUse hook 登録（matcher: "Bash|PowerShell", timeout 5）
- [x] features/auto_manage/output/scripts/hooks/ に実体配置、本体は symlink
- 背景: permission rule の PowerShell syntax は公式ドキュメント未確認、Bash deny だけでは Remove-Item 等で迂回されうる。claude-code-guide agent で確認した結果に基づき多層防御

## Phase: 0.2.19.主作業のフィーチャーブランチ運用を明文化 (2026-06-20)
- [x] 「割り込み作業とブランチ管理」に主作業ルールを追記 — master直でなく短命フィーチャーブランチで隔離、master=動くトランク、確認後merge、逐次1本。契機=reflect_colorでスポイト実験をmaster直で進め壊れ、reset --hardでの汚い後始末を招いた事故

## Phase: 0.2.20.tips参照仕組みの保留判断 (2026-04-24)
- [x] 当面: 「貯めるだけ」モード（tips 追記は行う、参照仕組みは未実装）
- [x] 候補B（キーワード hook 注入）を将来検討候補として残す
- 保留理由: キーワード選択が難しい
- 不採用: A=hook注入でコンテキスト肥大 / C・D=Claude任せで漏れ

## Phase: 0.2.21.git stash 系を deny に追加 (2026-04-24)
- [x] settings.json deny に `Bash(git stash *)` / `Bash(git stash)` を追加
- 背景: CLAUDE.md「割り込みは git worktree（stash禁止: 識別ミスリスク）」と
  既に明記されていたが permission rule 未反映だった、ハーネス層で強制
  ブロックする形に揃える

## Phase: 0.2.22.サブエージェントのモデル振り分け方針 (2026-07-02)
- [x] MODEL_ROUTING.md 新設: 難度→Haiku/Sonnet/Opus/メインの振り分け表・難度判定チェック（検証可能性ベース）・価格スナップショット（10:5:3:1）
- [x] CLAUDE.md 行動原則に発動トリガー1行を追加（bulk-verification 0.2.12 と同じ「CLAUDE.md=発動保証、別ファイル=手続き本体」の2段構成）
- 背景: ユーザー指示「簡単な作業をOpusやSonnetに委譲してほしい」。調査スイープ等をFableのまま並列委譲するとコストが並列数倍で嵩む。価格は claude-api skill で一次確認

## Phase: 0.2.23.PFDスキルの矢印表記ルール強化 (2026-07-15)
- [x] skills/pfd/SKILL.md 改訂（v1.1.0→v1.2.0）: 接続ルールに新設2点を追加（ルール5「矢印に文字ラベルを付けない」、ルール6「点線は遷移の戻り専用」で旧ルール5〜14を6〜16へ繰り下げ）
- [x] 使用要素表: 「補助入力矢印」を点線+ラベル方式から実線+ノード色分け方式に修正（旧`-.補助.->`表記を廃止）
- [x] mermaid実装メモ・drawio実装メモに同ルールの具体例を追記（分岐条件ラベルの許容記述を削除し、分岐先オブジェクト分割方式に置換）
- [x] pj_rat の deliverables 2件（backend_aws_plan_260712.md r2.1、system_flow_260715.drawio）を新ルールに合わせて修正、drawio_lint再合格
- 背景: pj_rat での実運用で担当が「補助入力=点線+ラベル」という誤用をしていることにユーザーが気付き指摘。点線=ループ戻り専用は実は既存スキル記述にあった規約（担当の誤読）。矢印ラベル禁止は「分岐条件は矢印ラベルで明示可」という旧mermaid節の記述を上書きする新規則としてユーザーが指定、スキル本体へ反映するようユーザーが明示指示

## Phase: 0.2.24.MODEL_ROUTING適用条件の明確化 (2026-07-20)
- [x] MODEL_ROUTING.md: 適用条件を追記 — 降格委譲は**メインが Fable のときだけ**（Fable 以外がメインなら本表不適用・委譲はメイン継承）。振り分け表の「メイン（Fable等）」を「メイン（Fable）」へ
- 背景: pj_likeRO 作業中に「簡単な作業は Opus4.8 へ必ず委譲、難題は fable 自身で」の指示があり、続けて適用条件が Fable メイン時のみである旨を追加指示
- 備考: この Windows 機では ~/.claude/MODEL_ROUTING.md への symlink が無く CLAUDE.md からの参照が切れている（link_claude.sh の対象確認が必要）→ 0.2.25 で解消（`bash link_claude.sh` 再実行で作成。対象漏れではなく未実行だった）

## Phase: 0.2.25.CLAUDE.md の構造再編（関心の分離・委譲体系・プロトコル外出し） (2026-08-18)
ブランチ: `feature/claude-md-smart`（ユーザーレビュー→master merge 待ち）。ユーザー要望「スリムでなくスマートに」= 行数削減でなく設計の筋を通す。方向 A/C/D を実施、B（Fable前提の書換）は協議中
- [x] A. CLAUDE.md を2部構成に再編 — 「共通契約（全実行主体）」（適用範囲／優先順位／報告と検証／変更管理／環境／コーディングスタイル）＋「対話セッションのルール（メインのみ）」（設計判断／作業ステップ／委譲／pj管理／ブランチ運用／知見の記録／~/.claude自体の変更）。既存ルールは全件保持（削除なし、移設のみ）。108行→73行
  - 新設: 「適用範囲」節 — サブエージェントにも配布される事実（公式docs: Explore/Plan 以外の全サブエージェントが CLAUDE.md 階層を受け取る）を明記し、承認前提ルールの適用外と「承認待ちで停止しない」を規定
- [x] A. MAINTENANCE.md 新設 — ~/.claude 保守ルール（実体と同期／GLOBAL_*記録／剪定／仕組みの所在）を CLAUDE.md から移設。`.claude/CLAUDE.md`（`@../MAINTENANCE.md` import shim）で dot_claude 作業時のみ自動読込。`.gitignore` を `.claude/*` + `!.claude/CLAUDE.md` に変更
- [x] C. MODEL_ROUTING.md 再構成 — 適用条件を先頭の節に昇格（適用主体=メインのみ／Fable メイン時のみ／対象経路）、旧 CLAUDE.md の Why 行（fan-out コスト・昇格リトライ）を「目的」に統合、価格表を単価比 10:5:3:1 ＋ claude-api skill 参照に置換（intro 価格の期限切れ等で陳腐化するため）
- [x] D. pj-management skill 新設（`skills/pj-management/SKILL.md` v1.0.0）— 旧 CLAUDE.md「pj管理」節の記録基準・タグ体系・中断スナップショット形式・初期化手順を移設。TEMPLATE_VISION/PROGRESS/DECISIONS.md を `skills/pj-management/templates/{VISION,PROGRESS,DECISIONS}.md` へ `git mv`、TEMPLATE_SKILL.md を `skills/TEMPLATE_SKILL.md` へ
- [x] link_claude.sh: dot_claude を指す壊れた symlink の掃除ロジックを追加（テンプレート移動で `~/.claude/TEMPLATE_*.md` が残骸化するため。dry-run で対象4件のみ検出を確認）
- [x] GLOBAL_VISION.md: 全体指針に「2部構成」「発動保証と手続き本体の分離」を追加、グローバル管理表を更新、latest_cache ライフサイクルの SessionStart 記述を hook 全自動（0.2.14 確認済み）へ訂正
- [x] ブランチ運用ルール改定（ユーザー指定 2026-08-18）: 階層 master → develop → feat系、命名 `feat/NN-<機能>-<趣旨>`（NN=issue番号、2桁ゼロ埋め、3桁になったら NNN）。CLAUDE.md「ブランチ運用」と MAINTENANCE.md を更新。旧 `feature/<機能>-<要旨>`（0.2.19）は廃止
- [x] dot_claude に develop ブランチ新設（master 8f1418b から分岐、origin へ push）。本ブランチ `feature/claude-md-smart` はルール前の例外として旧命名のまま（ユーザー決定）。gh は show-sai アカウントで honokani/dot_claude を解決できず、issue 操作は Claude 側から不可
- [x] public 化に向けた監査（ユーザー: 会社でも使うため public 化予定）: gitleaks 全履歴58コミット → leaks なし。履歴全文 grep でメール/URL/IP/ユーザー名パスは実質なし。要判断3点を提示 → ユーザー決定で (1) GLOBAL_PROGRESS 0.0.5 のプロジェクト名2件 を「他3件」へ置換、(2) skills/slide-writing/test_layout.py の見本フットノート（企業名入り）を削除。author メール（個人 Gmail）と、上記2点の**履歴内の残存**は public 化方式（visibility 変更 or squash 新規 repo）の決定待ち
- [x] read-only モード新設（会社PC等、clone 可・push 不可の環境向け）: `git config dot-claude.readonly true` で有効化。session-end-push.sh は push スキップ、session-start-pull.sh は `--ff-only`（失敗時ワークツリー不変で WARN）。テスト `scripts/test/hooks/test_sync_hooks.sh` 8ケース27アサーション Green。MAINTENANCE.md／features/auto_manage/plan.md・recovery.md に運用と復旧を記載
- [ ] ユーザー: 各環境で `bash link_claude.sh` 実行（MAINTENANCE.md リンク作成＋TEMPLATE_* 残骸掃除。この Windows 機は作成のみ実施済み、掃除は未実行）
- [ ] ユーザー: ブランチレビュー → develop へ merge → 正常稼働確認 → master へ merge → push
- [x] 履歴書換（ユーザー指示「履歴削除お願いします」）: スクラッチ clone で `uvx git-filter-repo --replace-text`（4ルール: 0.0.5 の2名→「他3件」、0.2.25 ログ内の2名→「プロジェクト名2件」、見本フットノート4行を削除）→ 61 コミット中 56 を書換、対象文字列の履歴内ヒット 7→0、各ブランチ先頭のツリー差分は想定ファイルのみ（master/develop: GLOBAL_PROGRESS.md・test_layout.py、feature: GLOBAL_PROGRESS.md・GLOBAL_DECISIONS.md）を確認後、ユーザー承認を得て master/develop/feature/claude-md-smart を force push（8f1418b / 8f1418b / bbb3b0f）。この機の repo は fetch + reset で新履歴に整合。GLOBAL_PROGRESS/DECISIONS 内の旧ハッシュ表記7箇所を commit-map で新ハッシュへ更新
  - author メール（個人 Gmail）は本人判断で残す（repo 所有者＝author）。public 化は現 repo の visibility 変更で行う方針
- [ ] ユーザー: 他の環境で次回起動前に `git -C <dot_claude> fetch origin && git -C <dot_claude> reset --hard origin/master`（未 push のローカル変更があれば先に退避。放置すると SessionStart の `pull --rebase` が旧履歴を rebase しようとして conflict で止まる）
- [ ] ユーザー: GitHub で visibility を public に変更（旧コミットは GitHub 側キャッシュに一定期間残りうる）
- [ ] B の扱いを決定（協議中: CLAUDE.md はサブエージェントにも配られるため「Fable なら不要」を理由に共通契約を削らない、を原則化するか）

## Phase: 0.2.26.traps 追加 — zsh chpwd hook によるコマンド置換汚染 (2026-08-19)
- [x] `traps/zsh_chpwd-hook_dirname-pwd.md` 新規 — dotfiles の `initialize.2.sh` が Mac で `command too long` になった件（zshrc の `chpwd() { _lsl }` が `$(cd "$(dirname "$0")" && pwd)` 内で発火し ls 出力が混入）。解決策 `cd ... >/dev/null && pwd`（bash/zsh 両対応）を推奨順で記載。ファイル名の照合語は誤爆しやすい `cd`/`command` を避けた
