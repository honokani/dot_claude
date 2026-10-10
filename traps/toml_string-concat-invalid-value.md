# toml — Python 流に文字列を分けて書くと `TOMLDecodeError: Invalid value`

## 症状
- Python の tomllib で読むと `tomllib.TOMLDecodeError: Invalid value (at line 34, column 13)`（2026-10-10、Python 3.12、Windows）
- 該当の行は、長い文字列を Python のように括弧と並べた文字列で分けたもの:
  ```toml
  name_rule = ("Answer in 1 to 3 plain words ... the name of "
               "an object. Do not interpret what the situation means.")
  ```

## 原因
- TOML には、括弧で囲む式も、並べた文字列をつなぐ仕組みも無い。値は 1 つの文字列でなければならない

## 対処
- 長い文字列は、複数行の基本文字列にして、行末の `\` でつなぐ（行末の `\` の後の改行と、次の行の先頭の空白が消える）:
  ```toml
  name_rule = """\
    Answer in 1 to 3 plain words that state only what is visible, such as a body position or the name of an \
    object. Do not interpret what the situation means."""
  ```
- `\` の前の空白は残るので、単語の区切りは `\` の前に置く
- 1 行に書いてもよい（TOML に行の長さの制限は無い）
- 関連: tomllib は TOML 1.0 なので、インラインテーブル `{ ... }` も 1 行で書く必要がある（複数行は TOML 1.1 から）。長い対応表は `[a.b]` の小さな表にする

## 観測
2026-10-10 pj_loratrain（判定ツリーの叩き台 tree.toml を 0.4 にしたとき）
