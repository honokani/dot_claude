# claude — `Error: claude native binary not installed.` で起動しない（npm グローバル版の自動更新が Windows で失敗した残骸）

## 症状
- ターミナルで `claude` を打つと、次を表示して終わる（zsh の alias 経由でも直接でも同じ）
  ```
  Error: claude native binary not installed.
  Either postinstall did not run (--ignore-scripts, some pnpm configs)
  or the platform-native optional dependency was not downloaded
  (--omit=optional).
  ```
- 起動したままの古いセッションでは、Grep ツールが `EUNKNOWN: unknown error, uv_spawn` で失敗する。下の対処の後は同じ呼び出しが通った（推測: セッションは起動時の実行ファイルのパスで ripgrep を起動しており、そのパスの中身が仮置きに変わったため）
- 2026-10-25、Claude Code 2.1.309 → 2.1.310、npm グローバル（`%APPDATA%\npm`）、node 24 / npm 11、Windows 11

## 原因
- npm 版の `bin/claude.exe` は 500 バイトの仮置き（上のエラーを echo するだけ）。postinstall（`install.cjs`）が `node_modules/@anthropic-ai/claude-code-win32-x64/claude.exe`（本物、約 300MB）をハードリンクかコピーで上書きして、初めて動く。npm の shim（`%APPDATA%\npm\claude`）は `bin/claude.exe` を exec するだけ
- 古い版のまま起動しているセッションの自動更新が、30 分おきに `npm install -g @anthropic-ai/claude-code@<最新>` を繰り返した（`~/.claude/.last-update-result.json` の `version_from` は実行中の版）。仮置きを展開した後で失敗した回があり、仮置きが残った。npm のログ（`%LOCALAPPDATA%\npm-cache\_logs\*-debug-0.log`）では次の 2 つが交互に出ていた
  - `EBUSY: resource busy or locked, copyfile '...\claude-code-win32-x64\claude.exe'`: 実行中のセッションの本体がパッケージのフォルダの中にあり、npm がフォルダを退避できない。`.last-update-result.json` には `"error_code":"update_apply_exe_locked"` と残る
  - `TAR_ENTRY_ERROR ENOSPC: no space left on device, write`: C: の使用率は 98%。そのとき何が容量を使っていたかは特定していない（調べた時点の空きは 26GB）
- 更新器は `npm install` の直前に、実行中の `bin/claude.exe` を `bin/claude.exe.old.<epoch ミリ秒>` にリネームすることがある（名前の時刻と npm のログの時刻が一致）。正しい新しい版が、この名前で残っていることがある

## 確かめ方
1. `A="$(cygpath -u "$APPDATA")/npm/node_modules/@anthropic-ai/claude-code"; ls -la "$A/bin/"` — `claude.exe` が 500 バイトなら仮置き
2. `cat ~/.claude/.last-update-result.json` と npm のログで、何で失敗したかを見る
3. 残っている本体（`$A/bin/claude.exe.old.*`、`$A/node_modules/@anthropic-ai/claude-code-win32-x64/claude.exe`）が目当ての版か、npm キャッシュの tarball と SHA-256 で照合する
   - tarball の integrity は `~/AppData/Local/npm-cache/_cacache/index-v5` を `claude-code-win32-x64-<版>.tgz` で grep する。実体は `content-v2/sha512/<hex の先頭2文字>/<次の2文字>/<残り>`（hex は integrity の base64 を戻したもの）
   - `tar -xOzf <tgz> package/claude.exe | sha256sum` なら、展開せずに比べられる
   - **`claude-code-win32-x64/package.json` が新しい版でも、`claude.exe` は実行中で置き換えられなかった古い版のことがある**（今回はサイズも SHA-256 も違った）。この状態でエラー文どおり `node .../install.cjs` を実行すると、古い版を置いてしまう
4. どのファイルが実行中かは、PowerShell で `[IO.File]::Open(<path>, 'Open', 'ReadWrite', 'ReadWrite, Delete')` が通るかで分かる（実行中は「別のプロセスで使用されている」で失敗する）。起動時刻は `Get-Process -Name claude | Select-Object Id, StartTime, Path`

## 対処
1. 仮置きをリネームで退避し、照合済みの本体を `bin/claude.exe` に戻す。リネームだけなので元に戻せて、容量も増えない
   ```bash
   B="$(cygpath -u "$APPDATA")/npm/node_modules/@anthropic-ai/claude-code/bin"
   mv -n "$B/claude.exe" "$B/claude.exe.stub"
   mv -n "$B/claude.exe.old.<照合済みのもの>" "$B/claude.exe"
   "$(cygpath -u "$APPDATA")/npm/claude" --version
   ```
2. 再発を止めるため、古い版で動き続けているセッションをすべて終了して、起動し直す（最新版で起動したセッションは、次の版が出るまで更新しない — 推測）
3. 整った状態に入れ直すなら、claude のセッションを全部終了してから、普通のターミナルで `npm install -g @anthropic-ai/claude-code@<版>` を実行する（セッションが 1 つでも残っていると EBUSY になる）
