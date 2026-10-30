# pre-tool-block-delete — 削除していないコマンドが「削除系」と誤判定されて止まる（xargs の後ろの rm、find の後ろの -delete、引用符直後の ri/rd/del）

## 症状
- Bash ツールの実行前に `ERROR: 削除系コマンドはブロックされました（pre-tool-block-delete.sh）` で止まる。削除していないのに止まった例（2026-10-30 の修正前）:
  - `ls *.log | xargs stat --format='%s %n'`（fo**rm**at）
  - `git ls-files | xargs grep -l 'permission denied'`（pe**rm**ission）
  - `find . -name '*.rlib' | xargs du -ch   # rmeta は別`（コメント中の **rm**eta）
  - `find /var/log -name '*-deleted*' -print`（`-delete` を含む引数）
  - `grep -c 'ri ' notes.txt`（`'ri ` が PowerShell の alias `ri` と同じ形）
- 複数行のスクリプト（heredoc で書いたものを含む）は 1 行ずつ検査され、コメントや heredoc の中身も対象。1 行でも当たれば全体が止まる。別セッションでは「確認のコマンドが削除系と誤って判定されたので、xargs を使わない形に分けて確認します」と回避していた

## 原因
- 間接系の式が `xargs.+(rm|rmdir|unlink)` で、単語境界が無く、xargs の後ろのどこかに「rm」の 2 文字があれば一致した（`grep -i` なので大文字小文字も区別しない）。`find.+-delete` も `-delete` が単独の引数かを見ていなかった
- 直接系の式は引用符・括弧の直後の `rm|rmdir|unlink|del|erase|Remove-Item|rd|ri|shred` も対象にしている（`pwsh -c 'del x'` や `(rm x)` を止めるため。issue #20）。grep パターンの `'ri '` が止まるのはその副作用で、こちらは残している（`'del foo.txt'` の検知と両立する式が無い）

## 対処
1. 0.2.76（2026-10-30）で間接系を「xargs が（フラグの後に）実行するコマンド名が rm/rmdir/unlink」と「単独の引数 `-delete`」だけに絞った。上の xargs / find の例は通る。`xargs -0 rm`・`xargs -I{} rm {}`・`xargs -n1 rmdir` は止まり、`xargs sh -c 'rm x'` は直接系（`'rm `）で止まる
2. それでも止まるとき: `'ri '` のような引用符直後の alias 名は、パターンを `"ri "` や `ri[[:space:]]` に変える。xargs を使わず `while read` や `find -exec` に分けるのも可
3. 本物の削除は書かない。退避は `mv` で `_gomi/`（CLAUDE.md 変更管理）
4. 判定だけ試すなら、試したいコマンド文字列をファイルに置き、1 行ずつ `jq -cn --arg c "$line" '{tool_input:{command:$c}}' | bash ~/.claude/scripts/hooks/pre-tool-block-delete.sh; echo $?`（exit 2 がブロック）。試すコマンドを Bash ツールの command に直接書くと、その呼び出し自体が止まる（2026-10-30 に実際に止まった）
5. 回帰テスト: `bash ~/.claude/scripts/test/hooks/test_block_delete_hook.sh`（通す例・止める例の両方を含む）
