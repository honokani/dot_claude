# `zsh -n`（構文チェック）がトップレベルの `$(<file)` を評価し `no such file or directory` で失敗する

## 症状

構文は正しく、実行（`zsh script.zsh`）も成功するのに、構文チェックだけが非0で終わる。

```
$ zsh -n tests/test_x.zsh
tests/test_x.zsh:56: no such file or directory: /stderr
```

`for f in *.zsh; do zsh -n "$f" || echo "SYNTAX NG: $f"; done` のような一括チェックで「構文NG」と誤判定される。

## 原因

`zsh -n`（NO_EXEC）でも、**トップレベル**に書いた `$(<file)`（cat 相当の特殊形）はファイルを開こうとする。
-n では変数代入が実行されないので `$sbx/stderr` は `/stderr` に展開され、存在しないファイルを開いて失敗する。

- 通常のコマンド置換 `$(cmd)` は -n で実行されない
- 関数本体の中の `$(<file)` は評価されない（関数定義は構文解析だけ）

## 解決策

- トップレベルでは `$(cat -- "$file")` を使う、または関数の中に入れる
- `zsh -n` の失敗が `no such file or directory` なら、構文エラーではなくこれを疑う

## 備考

- zsh 5.9（Git for Windows / MSYS2）で確認
- 実例: dotfiles `tests/test_memo_output.zsh`（2026-10-01, issue #3）
