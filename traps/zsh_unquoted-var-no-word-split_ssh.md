# zsh では `$x` が空白で分かれない（ssh 先のログインシェルが zsh だと、bash のつもりのループが壊れる）

## 症状

```sh
ssh host 'for x in "a.glb out_a" "b.glb out_b"; do set -- $x; python render.py $1 $2; done'
```

ssh 先のシェルが zsh だと、`$1` に `a.glb out_a` がまるごと入り、`$2` は空になる。今回は trimesh が

```
ValueError: string is not a file: `../outputs/a.glb out_a`
```

で止まった（引数がずれる・ファイルが見つからない、など別のエラーにもなる）。

## 原因

zsh は既定（`SH_WORD_SPLIT` オフ）で、引用していない `$x` を空白で分けない。bash の書き方の `set -- $x` は zsh では 1 つの引数になる。
`ssh host '...'` の中身はリモートのログインシェル（ここでは zsh）が解釈する。

## 解決策

- 分けたい所を明示する: zsh なら `${=x}`（`set -- ${=x}`）。bash と両用なら配列や関数の引数で渡す:

```sh
ssh host 'r() { python render.py "$1" "$2"; }; r a.glb out_a; r b.glb out_b'
```

- または bash で動かす: `ssh host 'bash -c "..."'`、長いものはスクリプトファイルにして `bash script.sh`
