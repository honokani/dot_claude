# claude — `claude -p --bare` が「Not logged in · Please run /login」になる（対話セッションはログイン済みでも）

## 症状
- Claude Code の Bash ツール（入れ子セッション）から `claude -p --bare --output-format json ...` を実行すると、JSON 封筒の `result` が `Not logged in · Please run /login`、`is_error: true`、`terminal_reason: api_error` で返る
- 同じ環境で `claude auth status` は `loggedIn: true`（claude.ai、firstParty）
- `--bare` を外すと成功する（`claude -p --no-session-persistence --output-format json --json-schema ... --tools ""`。2026-09-23、Claude Code 2.1.280 / Windows）

## 原因
- `--bare` は hooks・LSP・plugin sync 等を飛ばす最小モードで、ログイン情報の読み込みも飛ばすらしい（推測。ヘルプには明記なし）

## 対処
1. `--bare` を付けない。軽くしたいなら `--no-session-persistence` と `--tools ""` で足りる
2. 構造化出力は `--json-schema '<JSON Schema>'` ＋ `--output-format json`。結果は封筒の `structured_output`（パース済み）と `result`（JSON 文字列）の両方に入る。`stop_reason` は `tool_use` になる（ツール呼び出しで実装されている）
3. プロンプトは stdin で渡せる（`printf ... | claude -p ...`）。長文は argv でなく stdin
4. `--model opus` 等の別名が使える。コストは封筒の `total_cost_usd`（サブスク利用でも参考値が出る）
