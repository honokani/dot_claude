# bash — Bash ツールの長いコマンドが途中で切れる（`syntax error: unexpected end of file` / `unexpected EOF while looking for matching`）

## 症状
- 複数ファイルを heredoc でまとめて書く長いコマンドが、途中で打ち切られて bash に届く。エラーは `line N: syntax error: unexpected end of file`（heredoc の終端 EOF に到達しない）や `unexpected EOF while looking for matching ...`
- 観測1（2026-09-23 pj_building）: 約 317 行・約 8K 文字（コード＋日本語）のコマンドが 205 行目で切れた
- 観測2（同日、再現テスト）: 100 文字×90 行の heredoc（約 9.1K 文字）が 76 行目（約 7.5K 文字）で切れた。`wc -c` に到達せず
- 切れる位置は一定でない（文字数・バイト数・行数のどれとも単純に一致しない）

## 原因
- 未特定。ハーネス側のコマンド長上限か、モデル出力（tool_use 引数）の打ち切りかは Claude 側から判別できない（推測）

## 対処
1. 1 コマンドで書くファイルは 1 つにし、目安 6K 文字・150 行以下に収める。複数ファイルは別々の Bash 呼び出しに分ける（独立なら並列で出せる）
2. 大きいファイル（数百行）は Write ツールで書く（この打ち切りの観測なし）
3. 打ち切られた場合、bash は構文エラーで何も実行しないことが多いが、heredoc 途中で切れると部分内容が書かれることがある。失敗後は対象ファイルの末尾を確認する
