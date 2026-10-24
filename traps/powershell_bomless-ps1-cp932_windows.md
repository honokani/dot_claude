# PowerShell 5.1 — BOM 無しの .ps1 で、日本語の行の次の行が黙って消える

## 症状
- `powershell -File x.ps1` で、日本語コメントの次の行が実行されない。その行ではエラーが出ず、後で別の形で壊れる
  - 例: 次の行の `$base = 'C:\Users\...'` が消え、`"$base\bin\claude.exe"` が `C:\bin\claude.exe` になって「パス 'C:\bin\claude.exe' の一部が見つかりませんでした」
  - 例: 次の行のパイプの先頭（`Get-CimInstance ... |`）が消え、続きの `Select-Object ... | Format-List` だけが動いて何も出力されない

## 原因
- Windows PowerShell 5.1（`powershell.exe`）は、BOM 無しのスクリプトを既定のコードページ（日本語環境では cp932）で読む
- 行末の文字の UTF-8 の最後のバイトが cp932 の 2 バイト文字の先頭バイト（0x81–0x9F、0xE0–0xFC）だと、続く改行 LF（0x0A）と組みにされて改行が消え、次の行がコメントの続きになる。例: 全角の `）` は EF BC 89 で、0x89 が先頭バイト
- 改行が CRLF なら、巻き込まれるのは CR で LF が残るので起きない。Claude の Write ツールや printf で書いたファイルは LF

## 再現（2026-10-25、Windows 11、Windows PowerShell 5.1）
1 行目 `# test（テスト）`、2 行目 `"line2-ran"` のファイル:

| 書き方 | 2 行目 |
|---|---|
| BOM 無し・LF | 実行されない |
| BOM 無し・LF・1 行目の末尾を ASCII に（`# test（テスト）x`） | 実行される |
| UTF-8 BOM 付き・LF | 実行される |
| BOM 無し・CRLF | 実行される |

## 対処
- .ps1 は ASCII だけで書く（コメントも英語）。日本語を書くなら UTF-8 BOM 付きで保存する（bash で作るなら先頭に `printf '\xEF\xBB\xBF'`）
- PowerShell 7（`pwsh`）は BOM 無しを UTF-8 として読む仕様（ここでは未検証）
- 出力の日本語が化けて読めないときは `powershell ... 2>&1 | iconv -f CP932 -t UTF-8`（`powershell.exe` の出力は cp932）

## 補足
- `bash_powershell-invocation_windows.md` の「日本語混じり Regex のパースエラー（行末バッククォート継続行 + 日本語）」も、同じ読み違いが原因と思われる（推測: 先頭バイトの直後の ASCII 0x40–0x7E、たとえばバッククォート 0x60 も 2 バイト文字に取り込まれうる）
