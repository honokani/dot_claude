# git — Python で書き直したファイルが CRLF になり、差分なしなのに status が M のまま（needs update）

## 症状
- Windows の Python で `pathlib.Path.write_text(...)` してファイルを書き直すと、`git add` / `commit` 時に `warning: in the working copy of 'X', CRLF will be replaced by LF the next time Git touches it`（`.gitattributes` が `*.py text eol=lf` 等の場合。commit される中身は LF）
- その後 `sed -i 's/\r$//'` で LF に戻すと、`git diff` は空なのに `git status` が ` M`、`git update-index --refresh` が `X: needs update`（exit 1）のまま

## 原因
- `write_text` / `open(..., "w")` はテキストモードで、Windows では `\n` を `\r\n` に変えて書く
- 改行を戻した後も、index に記録された stat と食い違ったまま refresh で解消されない（core.autocrlf=true の環境。詳しい仕組みは未確認）

## 対処
1. Python で書くときは `write_text(s, encoding="utf-8", newline="\n")` か `write_bytes(s.encode("utf-8"))`
2. CRLF になってしまったら `sed -i 's/\r$//' <files>` で戻し、`git add -u` で index を取り直す（`git diff --cached` が空なら内容は変わっていない）
3. CRLF の有無は、次のどれかで確かめる（Git Bash の素の `grep` は当てにならない。下の「grep で \r を探せない」）
   - Python の `read_bytes().count(b"\r\n")`
   - `grep -cU $'\r' <file>`（`-U` を付ける。`$( )` の中では使わない）
   - `file <file>`（`with CRLF line terminators` と出る）
   - Claude Code の Grep ツール（ripgrep）でパターン `\r`

## grep で \r を探せない（MSYS2 の GNU grep 3.0）
- `grep -c $'\r' f` は、CRLF のファイルでも **0** を返す。GNU grep は MS-Windows ではテキストのファイルから CR を落としてから照合するため（`-U`/`--binary` で止まる。2026-10-23 に 3 行のファイルで確認: `-c` は 0、`-cU` は 2）
- `$( )` の中に `$'\r'` を書くと、grep には空のパターンとして届き、全部の行を数える（3 行のファイルで 3。原因未確認）。初回の観測「LF に戻した後も同じ数を返した」はこれと思われる（推測）
- つまり、0 件（見落とし）と全行（誤検出）の両方が起きる。`git add` が `CRLF will be replaced by LF` と警告したのに grep では見つからない、という形で気づく

## 観測
- 2026-10-09 pj_30croquis（パッチ用の Python スクリプトで .py / .toml / .md を書き換えた）
- 2026-10-23 pj_kite（パッチ用の Python スクリプトで .rs / .ts を書き換えた。`grep -q $'\r'` で調べて「CRLF なし」と誤って判断し、`git add` の警告で気づいた）
