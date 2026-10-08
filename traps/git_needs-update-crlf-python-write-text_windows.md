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
3. CRLF の有無は Python の `read_bytes().count(b"\r\n")` で数える。Git Bash の `grep -c $'\r$'` は LF に戻した後も同じ数を返し、当てにならなかった（原因未確認）

## 観測
2026-10-09 pj_30croquis（パッチ用の Python スクリプトで .py / .toml / .md を書き換えた）
