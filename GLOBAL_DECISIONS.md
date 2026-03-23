# GLOBAL_DECISIONS

> ~/.claude 関連の設定・運用判断ログ。

| Phase | 大分類 | 小分類 | 選択 | 却下案 | 理由 |
|-------|--------|--------|------|--------|------|
| 0.0.1.基盤構築 | pj管理 | 割り込み管理 | git worktreeで割り込み作業 | git stash | stashは識別ミスリスクが高い |
| 0.0.1.基盤構築 | pj管理 | グローバル管理 | GLOBAL_PROGRESS.md + GLOBAL_KEYWORDS.md新設 | CLAUDE.md内に記録 | CLAUDE.mdが肥大化する |
| 0.0.1.基盤構築 | 環境 | 作業ディレクトリ | workspace_for_claude専用ディレクトリ | プロジェクト内tmpなど | プロジェクト横断で使えるスペースが必要 |
| 0.0.1.基盤構築 | 環境 | Skills | `~/.claude/skills/`配置 | CLAUDE.md内にインライン | 再利用性・可読性 |
| 0.0.1.基盤構築 | pj管理 | CLAUDE.md | 124行→96行スリム化 | そのまま維持 | 情報量維持で冗長表現を圧縮 |
| 0.0.2.ツール整備 | pj管理 | DESIGN.md | ポールスター型に再定義 | 実装詳細も含める旧方式 | 実装詳細はコードが正、DESIGNは思想に集中 |
| 0.0.3.体系再編 | pj管理 | DESIGN.md | 設計思想3層構造 + ルールタグ | フラットなルール列挙 | 粒度の異なるルールが混在して判断に迷う |
| 0.0.3.体系再編 | pj管理 | KEYWORDS廃止 | DECISIONS.md + コード内コメントに一本化 | KEYWORDS.md維持 | 3行索引では判断材料不足、コード直接参照の方が速い |
| 0.0.3.体系再編 | pj管理 | トレードオフログ分離 | DECISIONS.mdとして独立ファイル化 | DESIGN.md内に維持 | 追記頻度がDESIGNの安定性と相性悪い、肥大化する |
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
| 0.0.4.フック導入 | 設計 | GLOBAL_DESIGN.md新設 | CLAUDE.mdと分離 | CLAUDE.md内に設計思想も記載 | CLAUDE.md=指示書、GLOBAL_DESIGN.md=設計書。責務分離 |
| 0.0.4.フック導入 | フック | latest_cacheマーカー配置先 | `$(pwd)/.claude/pjcache_marker_{id}` | `$(pwd)/.tmp/`や`.gitignore`追加 | `.claude/`は多くのプロジェクトで既にgitignore済み。追加設定不要 |
| 0.0.4.フック導入 | フック | latest_cache鮮度判定 | 更新日比較（cache ≥ max(3ファイル)で読む） | 24時間経過で無視 | 時間経過後こそログが助かる。pj管理ファイルの更新状況で判断する方が正確 |
| 0.0.4.フック導入 | フック | コンテキスト再注入方式 | SessionStartフックのstdout出力 | PostCompactのprompt型フック / PROGRESS.mdに書き出し | PostCompactはstdout無視。PROGRESS.md書き出しはcompact圧縮効果を食う。SessionStart stdoutが最も自然 |
| 0.0.4.フック導入 | 設計 | latest_cache内容指針 | レジスタダンプ比喩、30行上限 | 上限なし / PROGRESS.mdと統合 | 30行超はPROGRESS/DECISIONSへの書き出し不足の証拠。pj管理ファイルとの棲み分けを明確化 |
| 0.0.4.フック導入 | 設計 | 保存先構成 | ハイブリッド（pj管理はプロジェクト内、cacheのみ~/.claude/project_info/） | 全集中管理 | コードとの近さ優先。マーカーファイル不要化（パスから自動解決） |
| 0.0.4.フック導入 | フック | スナップショット保存先変更 | `~/.claude/project_info/` | 旧`~/.claude/compact-snapshots/` | ハイブリッド構成に合わせて移行。旧方式廃止 |
| 0.0.4.フック導入 | 設計 | ファイル管理の境界 | `.gitignore`を境界線として活用 | user/ディレクトリ分離 / 管理ファイルにパス列挙 | 追加の仕組みゼロ。git statusで未知ファイルを検知可能。既存の.gitignoreが事実上の境界として機能済み |
| 0.0.4.フック導入 | 用語 | 「開発管理」→「pj管理」 | pj管理 | 開発管理のまま | タイピング短縮＋開発以外のプロジェクトにも適用可能にするため |
| 0.0.4.フック導入 | 設計 | 境界原則の配置先 | GLOBAL_DESIGN.mdのみ | CLAUDE.mdにも追記 | CLAUDE.mdはグローバル。全プロジェクトで読まれるため~/.claude固有のルールは不適切 |
