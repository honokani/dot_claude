# GLOBAL_DECISIONS

> ~/.claude 関連の設定・運用判断ログ。

| Phase | 大分類 | 小分類 | 選択 | 却下案 | 理由 |
|-------|--------|--------|------|--------|------|
| 0.0.1.基盤構築 | pj管理 | 割り込み管理 | git worktreeで割り込み作業 | git stash | stashは識別ミスリスクが高い |
| 0.0.1.基盤構築 | pj管理 | グローバル管理 | GLOBAL_PROGRESS.md + GLOBAL_KEYWORDS.md新設 | CLAUDE.md内に記録 | CLAUDE.mdが肥大化する |
| 0.0.1.基盤構築 | 環境 | 作業ディレクトリ | workspace_for_claude専用ディレクトリ | プロジェクト内tmpなど | プロジェクト横断で使えるスペースが必要 |
| 0.0.1.基盤構築 | 環境 | Skills | `~/.claude/skills/`配置 | CLAUDE.md内にインライン | 再利用性・可読性 |
| 0.0.1.基盤構築 | pj管理 | CLAUDE.md | 124行→96行スリム化 | そのまま維持 | 情報量維持で冗長表現を圧縮 |
| 0.0.2.ツール整備 | pj管理 | VISION.md | ポールスター型に再定義 | 実装詳細も含める旧方式 | 実装詳細はコードが正、DESIGNは思想に集中 |
| 0.0.3.体系再編 | pj管理 | VISION.md | 設計思想3層構造 + ルールタグ | フラットなルール列挙 | 粒度の異なるルールが混在して判断に迷う |
| 0.0.3.体系再編 | pj管理 | KEYWORDS廃止 | DECISIONS.md + コード内コメントに一本化 | KEYWORDS.md維持 | 3行索引では判断材料不足、コード直接参照の方が速い |
| 0.0.3.体系再編 | pj管理 | トレードオフログ分離 | DECISIONS.mdとして独立ファイル化 | VISION.md内に維持 | 追記頻度がDESIGNの安定性と相性悪い、肥大化する |
| 0.0.3.体系再編 | pj管理 | GLOBAL_KEYWORDS廃止 | GLOBAL_DECISIONS.mdに変換 | GLOBAL_KEYWORDS.md維持 | プロジェクト側と同じ理由で一貫性確保 |
| 0.0.3.体系再編 | コーディング | 関数型スタイル拡張 | 言語横断で関数型+Pythonルール明示 | Rust限定のまま | Python作業増加に伴い全言語で一貫したスタイルが必要 |
| 0.0.3.体系再編 | コーディング | Python実行 | `uv run python`強制、python直打ち・pyenv禁止 | python直接実行 | Windows環境でのPATH問題回避、uv統一 |
| 0.0.3.体系再編 | 変更管理 | メモ化ルール | 繰り返し取得処理のメモ化を明文化 | 暗黙のまま | API呼び出し等の無駄な再取得を防止 |
| 0.0.3.体系再編 | pj管理 | CLAUDE.md整理 | workspace/Skills/tips/デバッグの重複記述を統合・簡素化 | そのまま維持 | 行数削減と参照先の一元化 |
| 0.0.3.体系再編 | pj管理 | Phase導入 | GLOBAL_DECISIONS.mdにもPhaseカラム導入 | 日付カラムのまま例外扱い | 画一的運用を優先、特殊操作を避ける |
| 0.0.3.体系再編 | pj管理 | Phase番号体系 | セマンティックバージョニング準拠 | 連番・日付ベース | 変更規模の意味づけが自然、初期構想完成=1.0.0で区切りが明確 |
| 0.0.4.フック導入 | フック | compact状態退避 | PreCompact+PostCompactの2段構成 | PreCompactのみ | PostCompactでサマリーも記録することで、次セッションで「何が圧縮されたか」も復元可能 |
| 0.0.4.フック導入 | フック | スナップショット保存先 | `~/.claude/compact-snapshots/` | プロジェクト内 | プロジェクト横断で使うグローバルフックなのでグローバル配置 |
| 0.0.4.フック導入 | フック | スクリプト配置 | `~/.claude/scripts/hooks/` | `~/.claude/hooks/` | hooksディレクトリはClaude Code本体と混同する可能性あり、scripts/hooks/で明示的に分離 |
| 0.0.4.フック導入 | 設計 | GLOBAL_VISION.md新設 | CLAUDE.mdと分離 | CLAUDE.md内に設計思想も記載 | CLAUDE.md=指示書、GLOBAL_VISION.md=設計書。責務分離 |
| 0.0.4.フック導入 | フック | latest_cacheマーカー配置先 | `$(pwd)/.claude/pjcache_marker_{id}` | `$(pwd)/.tmp/`や`.gitignore`追加 | `.claude/`は多くのプロジェクトで既にgitignore済み。追加設定不要 |
| 0.0.4.フック導入 | フック | latest_cache鮮度判定 | 更新日比較（cache ≥ max(3ファイル)で読む） | 24時間経過で無視 | 時間経過後こそログが助かる。pj管理ファイルの更新状況で判断する方が正確 |
| 0.0.4.フック導入 | フック | コンテキスト再注入方式 | SessionStartフックのstdout出力 | PostCompactのprompt型フック / PROGRESS.mdに書き出し | PostCompactはstdout無視。PROGRESS.md書き出しはcompact圧縮効果を食う。SessionStart stdoutが最も自然 |
| 0.0.4.フック導入 | 設計 | latest_cache内容指針 | レジスタダンプ比喩、30行上限 | 上限なし / PROGRESS.mdと統合 | 30行超はPROGRESS/DECISIONSへの書き出し不足の証拠。pj管理ファイルとの棲み分けを明確化 |
| 0.0.4.フック導入 | 設計 | 保存先構成 | ハイブリッド（pj管理はプロジェクト内、cacheのみ~/.claude/project_info/） | 全集中管理 | コードとの近さ優先。マーカーファイル不要化（パスから自動解決） |
| 0.0.4.フック導入 | フック | スナップショット保存先変更 | `~/.claude/project_info/` | 旧`~/.claude/compact-snapshots/` | ハイブリッド構成に合わせて移行。旧方式廃止 |
| 0.0.4.フック導入 | 設計 | ファイル管理の境界 | `.gitignore`を境界線として活用 | user/ディレクトリ分離 / 管理ファイルにパス列挙 | 追加の仕組みゼロ。git statusで未知ファイルを検知可能。既存の.gitignoreが事実上の境界として機能済み |
| 0.0.4.フック導入 | 用語 | 「開発管理」→「pj管理」 | pj管理 | 開発管理のまま | タイピング短縮＋開発以外のプロジェクトにも適用可能にするため |
| 0.0.4.フック導入 | 設計 | 境界原則の配置先 | GLOBAL_VISION.mdのみ | CLAUDE.mdにも追記 | CLAUDE.mdはグローバル。全プロジェクトで読まれるため~/.claude固有のルールは不適切 |
| 0.0.4.フック導入 | フック | スクリプトリネーム | pre-compact→save-context-cache, post-compact→append-compact-summary | 旧名維持 | 用途を名前で表現。PreCompact専用ではなくSessionEndでも共用するため |
| 0.0.4.フック導入 | フック | SessionEndフック追加 | save-context-cache.shをSessionEndでも発火 | SessionEndなし（PreCompactのみ） | セッション正常終了時にもキャッシュを生成。compactされずに終了するケースをカバー |
| 0.0.4.フック導入 | フック | ~~PostCompact/SessionStartフック解除~~ | ~~CLAUDE.md規約によるClaude主導に移行~~ | ~~フック維持~~ | **誤判断→撤回**。compact_summaryの取得はPostCompactフックでしかできない。CLAUDE.md規約では代替不可。PostCompactフック復活(0.0.4内で修正) |
| 0.0.4.フック導入 | フック | SessionStartフック解除 | CLAUDE.md規約によるClaude主導に移行 | フック維持 | SessionStartのstdout注入はCLAUDE.mdの手順指示で同等機能を実現可能。読み込み側はClaude主導で問題なし |
| 0.0.4.フック導入 | フック | duration_ms記録 | save-context-cache.shに実行時間計測追加 | 計測なし | 傾向分析用。フロントマターに記録 |
| 0.0.4.フック導入 | 設計 | 「無いときは無い」の適用範囲 | Ctrl+C/SIGKILL等の強制終了時のみ | /exitや正常終了も含める | ユーザー原典:「コレCtrlC終了や強制終了のタイミングでのホックとか可能？」→不可→「無いときは無い」。正常終了(/exit)はSessionEndフックが発火するので保存すべき |
| 0.0.4.フック導入 | フック | SessionEndにもサマリー記録 | append-compact-summary.shをSessionEndでも発火 | git状態のみ記録 | サマリーが機能の核。dttmとgit diff statだけでは引き継ぎにならない。compact_summaryが無い場合はtranscript末尾から抽出 |
| 0.0.4.フック導入 | フック | マーカー再利用 | 既存マーカーがあればID再利用+追記 | 毎回新規ID生成 | /compact→/compactや/compact→/exitで1回目のログが孤立する問題を防止。1セッション=1キャッシュファイルに集約 |
| 0.0.4.フック導入 | 運用 | セッション継続方式 | `claude --continue`をデフォルト運用 | latest_cacheによる復元 | `--continue`は会話履歴を完全復元。latest_cacheは圧縮要約でしかない。resumeの存在を設計段階で見落としていた |
| 0.0.4.フック導入 | フック | SessionEndフック解除 | settings.jsonから削除（スクリプト残置） | フック維持 | `--continue`常用なら/exit時のキャッシュ生成は不要。PreCompact/PostCompactは引き続き有用（compact時の詳細保存） |
| 0.0.4.フック導入 | 運用 | latest_cacheの位置づけ | resumeもcontinueもしなかった場合のフォールバック | セッション間引き継ぎの主要手段 | `--continue`が主、latest_cacheは副。セッション保存/復元パターン検討は不要化 |
| 0.0.5.命名整理 | pj管理 | 設計思想ファイル名 | VISION.md | DESIGN.md維持 | "Design"がUI/UX文脈の"Design System"（カラー・タイポ・コンポーネント等のスタイルガイド）を強く連想させ、設計思想ファイルとして混同を招く。"VISION"は「あるべき姿/Why」と直結し、命名と内容が一致する。命名一貫性のためTEMPLATE_DESIGN→TEMPLATE_VISION、GLOBAL_DESIGN→GLOBAL_VISIONも改名。グローバル~/.claudeおよび全6プロジェクトに波及 |
| 0.0.5.命名整理 | フック | session-start.sh鮮度判定 | VISION.mdのみ参照（互換なし） | DESIGN.md/VISION.mdフォールバック | 完全切替方針。全プロジェクトを同タイミングで改名するため互換期間不要 |
| 0.0.6.管理対象整理 | 管理境界 | skills/recall分類 | .gitignoreのシンボリックリンク実体セクション | キャッシュ系セクション | session-viewer依存のシンボリックリンクであり、キャッシュではない |
| 0.1.0.dot_claude単独化 | 管理境界 | リポジトリ分離方針 | 独立リポジトリ+dotfiles連携 | dotfilesサブモジュール / ~/.claude完結 | ライフサイクル違い（dotfiles年次・dot_claude週次）、必須性違い（Claude Code環境のみ）、既存のpyenv初期化パターンに整合 |
| 0.1.0.dot_claude単独化 | 管理境界 | 履歴保持方法 | git clone(ローカルパス) → remote切替push | filter-repo / 新規init | 全履歴保持しつつ1コマンドで完結、submodule不要 |
| 0.1.0.dot_claude単独化 | 管理境界 | リンク配置方式 | ~/.claude/配下の個別項目リンク | ~/.claude/丸ごとリンク | Claude Codeが~/.claude/直下に自動生成（history.jsonl等）するため、dotfiles作業ツリーを汚染しない構成が必要 |
| 0.1.0.dot_claude単独化 | 管理境界 | ~/.claude/.gitの扱い | 保険として凍結（削除しない、commit/pushもしない） | rm -rf削除 | 履歴スナップショットを保険として保持。現役リポジトリは~/git_clone/dot_claude/に一本化 |
| 0.1.1.link_claude.sh冪等性対応 | 運用 | skills/のPermission denied対処 | Claude Code終了後に手動再実行 | 個別skill単位でリンク / rm -rf強行 | 自プロセスが~/.claude/skills/のハンドルを保持しているため。ハンドル解放後の単純再実行が最も安全で、構造変更不要 |
| 0.1.1.link_claude.sh冪等性対応 | 運用 | _bkの衝突対処 | 連番サフィックス（_bk, _bk1, _bk2...） | 上書き / スキップ | データ損失防止とバックアップ履歴保持の両立。複数回実行時も安全 |
| 0.1.1.link_claude.sh冪等性対応 | 運用 | symlink既存時の挙動 | readlink比較で一致ならスキップ | 常にrm→再作成 | 冪等性確保、エラー時の原因切り分けが容易、Claude Code実行中の不要なrmを回避 |
| 0.1.1.link_claude.sh冪等性対応 | 運用 | ln実行オプション | ln -sn（no-dereference） | ln -s | 既存ディレクトリ先への副作用リンク作成を防止（skills/skillsケース） |
| 0.1.2.plans対象外化 | 管理境界 | plans/の位置づけ | git対象外、~/.claude/配下の実ディレクトリとして維持 | dot_claudeで共通管理 | 計画はプロジェクト固有でdot_claude横断性を損なう。~/.claude/では実ディレクトリ化し、dot_claude側は削除+ignoreで再発防止 |
| 0.2.0.自動管理基盤設計 | 運用 | pull実行タイミング | SessionStart hook同期実行 | バックグラウンド / shell起動時 | セッション開始前に確実にCLAUDE.md等を最新化する必要。通常数百msで完了、体感差なし。conflict時のみstdout警告で報告 |
| 0.2.0.自動管理基盤設計 | 運用 | 機微情報チェックツール | gitleaks | 自作grep / GitHub Secret Scanning | パターン網羅性とカスタマイズ性を両立。TOMLでrule追加可能。OSS・継続メンテナンス。自作は網羅性で劣る、GH Secret Scanningは事後検知 |
| 0.2.0.自動管理基盤設計 | 運用 | カスタムruleの保管 | ~/.claude/gitleaks/（git管理外） | dot_claude内（git管理） | 取引先名リスト自体が機微情報。dot_claudeが公開されても漏れない設計。公開可能な汎用ruleはdot_claude/.gitleaks.toml に分離 |
| 0.2.0.自動管理基盤設計 | 運用 | 設計の配置場所 | dot_claude/auto_manage/ ディレクトリ | 単一 plan.md / GLOBAL_PROGRESSへ散在記述 | 設計・計画・フロー図・回収手順を分離し、Phase進行と無関係に参照可能に。README.mdで目次化 |
| 0.2.0.自動管理基盤設計 | ドキュメント | フロー記述の方針 | mermaid図 + PFD精神の箇条書き併記 | mermaidのみ / 箇条書きのみ | mermaidは俯瞰性、PFD精神の箇条書き（タスクとオブジェクト分離）は入出力の明示性に強み。両方併記で読み手の理解経路を選択可能に |
| 0.2.0.自動管理基盤設計 | ドキュメント | SKILL.md改善 | 冒頭に「設計思想（Why）」「オブジェクトの具体性」節を追加 | 既存記述のまま（Whatのみ） | ルールのWhatだけだと視覚接続ルールとしてしか読めず、関数的composability検証手段という本質が伝わらない。抽象名vs実体名の対比表で具体性の基準を明示 |
| 0.2.0.自動管理基盤設計 | ドキュメント | 箇条書きフローの記法 | `◯ オブジェクト → [ タスク ] → ◯` の交互連鎖 | タスク中心に入出力をラベル付与 | 前者はタスク直結禁止・合成可能性の目視検証が可能。後者は視覚的にタスクが主役となりオブジェクトが従属化、合成境界が曖昧になる |
| 0.2.0.自動管理基盤設計 | ドキュメント | flow_diagram.mdの立ち位置 | PFDフロー箇条書き専用、記法解説はSKILL.md参照 | mermaid併記 / 記法解説の併記 | 役割の重複と基準混在を解消。PFD精神を反映しないmermaidと反映した箇条書きが混在すると読み手が迷う。記法は skills/pfd/SKILL.md に一元化して単一情報源化 |
| 0.2.0.自動管理基盤設計 | ドキュメント | ファイル配置図の配置先 | plan.md に集約 | flow_diagram.mdに同居 | 静的関係（どのファイルがどこにあるか）は設計ドキュメント（plan.md）側に置き、flow_diagram.mdは動的フロー（入出力の連鎖）のみに絞る |
| 0.2.0.自動管理基盤設計 | ドキュメント | PFDスキルの適用範囲 | 「フローを描いて」指示は全てPFD前提（drawio/mermaid/箇条書き問わず） | 形式ごとに別スキル / 明示指示時のみPFD | ユーザー原典: 「今後『フローを描いて』でpdf以外を指すことは有りません」。素のフローチャートを廃し、PFD精神（タスク=関数、入出力=オブジェクト）を常時適用する |
| 0.2.0.自動管理基盤設計 | ドキュメント | flow_diagram.mdの表現形式 | PFD準拠のmermaid | 箇条書き / drawio | mermaidは名称付き・色分け・視覚明瞭で可読性が高い一方、箇条書きは簡潔だがノード参照が弱い。drawioはSKILL.md例示用として残す |
| 0.2.1.gitleaks pre-commit | セキュリティ | gitleaks実行形態 | core.hooksPath経由のpre-commit hook | husky / manual実行 | hooksPathなら link_claude.sh で clone直後に設定でき、global install不要。他マシンへの展開が容易 |
| 0.2.1.gitleaks pre-commit | セキュリティ | ルール階層 | 汎用rule(dot_claude/.gitleaks.toml) + ローカル(~/.claude/gitleaks/rules.toml) の2段 | 単一ファイル / dot_claude内にローカルrule混在 | 取引先名リスト自体が機微情報なので git管理外に置く必要。gitleaks は --config が1つだけなので hook 内で2回実行する方式で両立 |
| 0.2.1.gitleaks pre-commit | セキュリティ | allowlistの適用 | dot_claude/.gitleaks.toml paths でドキュメント内例示を除外 | ドキュメントから例示削除 / allowlist無し | 記法説明にパターン例が必要、毎回手動修正は非現実的。allowlist で pre-commit 誤検知回避 |
| 0.2.3.SessionEnd auto-push | 運用 | auto-push発火タイミング | SessionEnd hook | SessionStart / PreCompact | セッション終了時のみ push することで、作業中の未完成 commit の誤push を避ける（作業途中なら commit 自体していないはず） |
| 0.2.3.SessionEnd auto-push | 運用 | 低エントロピー文字列の扱い | gitleaks デフォルトの entropy判定を受け入れる | 全文字列を検出する強化rule作成 | gitleaks の entropy判定は誤検知抑制目的。実運用の本物キーは高エントロピーで検出される。整然パターン（順列文字列・公式example）はテスト用で、本番混入は想定外 |
| 0.2.2.SessionStart pull 同期 | 運用 | スクリプト分割 | session-start-pull.sh + session-start-cache.sh の2本 | 単一scriptに統合 | pullとcacheは責務が異なる。分割して単独改修可能にし、片方の設定削除が他方に影響しないようにする。既存session-start.sh は cache処理なのでrenameで意図を明示 |
| 0.2.2.SessionStart pull 同期 | 運用 | hook実行順序 | pull → cache | cache → pull | pullでCLAUDE.md等が更新された後にcache鮮度判定する方が正しい。現状cacheはプロジェクトローカルでdot_claudeと独立だが、将来cacheがdot_claude依存になっても破綻しない順序にしておく |
| 0.2.2.SessionStart pull 同期 | 運用 | pull失敗時の起動挙動 | stdout警告のみ、exit 0で起動継続 | exit 1で起動ブロック | pull失敗は手動解決すべき事象だが、そのためにClaude Code起動自体を止めると不便。context内にWARN出力して気づけるようにする |
| 0.2.2+0.2.3.hook改善 | 運用 | REPOパス解決方式 | ~/.claude/CLAUDE.md symlink から readlink で動的解決 | $HOME/git_clone/dot_claude ハードコード | Windowsでは /c/git_clone/... に配置されるなど環境でパスが異なる。symlink経由なら link_claude.sh がリンクを張った時点で自動的に正しいパスが得られ、hook script は OS/配置に依存しない |
| 0.2.5.tips命名規則整備 | ドキュメント | 命名規則の配置先 | tips/README.md（tips直下） | CLAUDE.mdに直書き | CLAUDE.mdは最小維持方針。詳細規則は対象ディレクトリ直下に置く方が発見しやすく、CLAUDE.mdからは参照リンクのみ |
| 0.2.5.tips命名規則整備 | ドキュメント | 区切り文字の使い分け | 要素区切り `_` / 単語内連結 `-` | 全て `_` / 全て `-` | `windows-terminal`（1主題：Windows Terminalアプリ） vs `windows_terminal`（2要素：環境+話題）を一目で区別可能 |
| 0.2.5.tips命名規則整備 | ドキュメント | 要素順序 | 主題_細目_環境（環境は末尾、省略可） | 環境_主題_細目 / 任意 | 検索軸となる主題を先頭、付帯情報の環境を末尾に。環境非依存tipsは環境省略で短くなる |
| 0.2.6.同期運用ルール明文化 | 運用 | pull/push の実行タイミング | 編集前pull / 編集後pushを毎回手動実行 | SessionEnd auto-pushに任せる | ユーザー原典「毎回pushして。コレはルール」「自動pushはあくまで失敗防止ネット」。複数環境編集で手動pushが遅れると他環境conflictの種。auto-pushは取りこぼし救済の保険であり第一選択ではない |
| 0.2.7.機能単位ディレクトリ化 | 管理境界 | 機能単位のディレクトリ構造 | features/<name>/ に設計+output集約、本体から symlink | 本体直下に実装 + auto_manage に設計のみ | ユーザー指摘「features は機能本体の意味。設計資料だけ置くと意味不一致」。機能ごとの物理完結（削除時ディレクトリごと）と命名の意味一貫性を両立。symlink運用は link_claude.sh で既に確立されたパターンで新規コスト低い |
| 0.2.7.機能単位ディレクトリ化 | 管理境界 | symlinkの配置方向 | 本体 → features/auto_manage/output/ への relative symlink | features側にダミー / 本体直接配置継続 | 実体は機能ディレクトリに集約（机能の所属が明確）、本体には後方互換のsymlink（settings.json や core.hooksPath の既存パスを変更せずに済む） |
| 0.2.8.blog-crawler削除 | Skills | blog-crawlerの取り扱い | gitとローカル両方から完全削除 | .gitignoreでローカル残す / 現状維持 | 使用実績なし、かつはてなブログへの自動クロールは公開リポジトリで配布するには行儀が悪い（スクレイピング負荷・robots.txt/規約遵守の観点）。必要時は個別プライベートリポジトリで別途実装 |
| 0.2.9.テンプレ整備 | ドキュメント | SKILL.md共通形式の決定 | 既存3 skillのfrontmatter形式を TEMPLATE_SKILL.md として正規化 | 形式自由 / pfd の簡易形式を許容 | Claude Codeはfrontmatterベースで skill を認識、pfdだけ欠けていたので統一。現フォーマットがベストかは未検証、将来レビュー余地ありとしてテンプレ末尾にコメント残す |
| 0.2.9.テンプレ整備 | 命名 | rust tips の `_` 使い分け | rename で `-` 連結に統一（const-design / effect-system / how-to-debug） | 現状維持 | tips/README.md 規則に厳密適用。rust_egui / serde / windows は1単語or環境なので変更不要 |
| 0.2.10.凍結終了 | 管理境界 | ~/.claude/.gitの扱い | 削除（Phase 0.1.0 の凍結方針を終了） | 凍結維持 | 独自履歴ゼロ・working diff 39件の偽差分で保険として機能していない。最終commit `5b48644` は dot_claude 側にも保持済。現役リポジトリ /c/git_clone/dot_claude/.git に一本化 |
| 0.2.11.記録基準明文化 | pj管理 | PROGRESS/DECISIONS の記録対象 | 事前予定+挙動変更 / A/B根拠+疑問実装の理由 に絞る | 全変更を記録 / 主観判断 | 「予定外×迷ってない×小変更」を対象外にすると、PROGRESSは引き継ぎ意図、DECISIONSは判断根拠に集中でき、git logで追える情報との重複を避けられる。既存挙動の破壊・読者が疑問に思う実装だけ例外として許容 |
| 0.2.11.記録基準明文化 | pj管理 | GLOBAL側の記述スタイル | pj管理ルールへの参照（「pj管理と同一基準」と書くだけ） | GLOBAL側にも全ルール複写 | 複写は乖離の原因。pj管理側を単一情報源として参照するのが保守性高い |
| 0.2.12.bulk-verification | Skills | 虚偽完了報告対策の配置形態 | Skill本体（手続き）+ CLAUDE.md行動原則（hard trigger）の2段 | Skill単独 / CLAUDE.md直書き | Skill単独だと「bulk task と認識できないと発動しない」発動漏れリスク。CLAUDE.md単独だと長文手続きでファイル肥大化。CLAUDE.md = 発動保証（1行）、Skill = 手続き本体、で役割分離 |
| 0.2.12.bulk-verification | Skills | 形質矯正の手段選択 | サブエージェント並列化による観測可能性確保 | 当方への注意喚起 / memory ファイル追加 | 当方の意志に依存する手段（注意喚起・memory）は実証的に無効（同セッション内で3ラウンド虚偽報告→memory更新→なお再発）。サブエージェント分割は「項目1個しか見ないサブは『全件チェック』と虚偽できない」物理的制約で、当方の発動・記憶を必要としない |
| 0.2.12.bulk-verification | Skills | サブ出力フォーマット | quoted-pair（TXT vs PY を要素ごと verbatim 並記）+ verdict 強制 | 自由形式 / 差分のみ報告 | 要素を quote させることで『見たフリ』が物理的に成立しない（読まないと quote できない）。サブも同じ訓練分布の AI で同種の虚偽挙動可能性があるため、出力フォーマットで構造的に縛る |
| 0.2.13.タグ体系改定 | pj管理 | VISION.mdルールタグ | `[unittest]`/`[qchecktest]` を直接付与、`[testable]` 廃止 | `[testable]` 付与→後で2分類の2段階方式（bootcamp第1・2回方式） | タグ=検証チャネルの宣言に純化。中間タグは分類作業を2回にするが情報を足さない。テスト作成時に何をすべきかが最初から一意 |
| 0.2.13.タグ体系改定 | pj管理 | テスト未作成項目の扱い | 理由で分岐: 思想由来→`[philosophy]`降格／未実装→タグ据置 | 一律`[philosophy]`降格（bootcamp第2回方式） | 恒久属性（検証可能性）と一時状態（実装有無）の混同を排除。「タグ付き×テスト不在」を検出可能なギャップとして可視維持。VISION先行運用では新規項目が必ず未実装期間を通過するため、一律降格は新機能タグを誤って洗い流す |
| 0.2.14.運用棚卸し | 運用 | latest_cacheの去就 | 維持（hook全自動）+ CLAUDE.mdの手動手順を削除 | 機能ごと廃止 / 手動手順の維持 | old/に7PJ分の消費実績（直近2026-06-10朝）があり「--continue主・cacheフォールバック」の設計通り現役稼働。不稼働に見えたのはhook自動化による不可視性。手動手順はsession-start-cache.shと完全二重でClaude側は常に空振りしていた |
| 0.2.14.運用棚卸し | 運用 | tipsの去就 | 維持 + 参照トリガーをCLAUDE.mdに明文化 | 廃止 / project memoryへ統合 / 現状維持 | 内容は有用・生産側は稼働中で、死んでいたのは参照側（本セッションでtips記載済みの罠を未参照のまま再踏みした実証）。project memoryはプロジェクト別格納でクロスプロジェクト知見の代替にならない。書き込み専用ストア化の対策はトリガーの明文化 |
| 0.2.14.運用棚卸し | 運用 | トピックマーカーの去就 | 剪定（候補版から削除） | 維持 / 形式を変えて存続 | 剪定プロトコル（0.2.13）適用第1号。導入判断の記録なし・使用実績なし・ユーザー証言「古い取り決め」の3点一致。発言時の影響範囲明示は変更管理ルールが、検索はDECISIONS.mdの大分類/小分類列が既に代替している |
