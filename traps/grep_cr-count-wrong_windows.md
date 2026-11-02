# grep で CR（\r）を数えると黙って違う数になる（0件、またはコマンド置換の中で全部の行）— MSYS2/git bash

## 症状

CRLF の確かめに `grep -c $'\r'` を使うと、エラー無しで違う数が出る。

- そのまま打つと、CRLF の行があっても **0**（exit 1）。「LF のまま」と誤って判定する
- `"$(grep -c $'\r' f)"`・`x=$(grep -c $'\r' f)` のようにコマンド置換の中に置くと、**全部の行の数**が出る（パターンが空になったのと同じ）。「全部 CRLF」と誤って判定する
- 長いコマンドの中では、`command substitution: line 5: syntax error near unexpected token ')'` になったこともある（同じコマンドの2つ目の置換は全部の行の数 128 を返した。2026-11-02 pj_traincolor）

## 検証（再現実績: 2026-11-02, GNU grep 3.0, GNU bash 4.4.23(1)-release (x86_64-pc-msys), igncr off）

3行のうち1行だけ CRLF のファイル（`printf 'a\r\nb\nc\n' > f`）で:

| コマンド | 結果 |
|---|---|
| `grep -c $'\r' f` | **0**（exit 1）← 失敗 |
| `LC_ALL=C grep -c $'\r' f` | **0**（exit 1）← 失敗 |
| `grep -c "$(printf '\r')" f` | **0** ← 失敗 |
| `echo "$(grep -c $'\r' f)"`・`x=$(grep -c $'\r' f)`・引用符なしの `$(…)` | **3**（全部の行）← 失敗 |
| `grep -c -U $'\r' f` | 1 ← 回避策 |
| `rg -c $'\r' f` | 1 ← 回避策 |
| `tr -cd '\r' < f \| wc -c` | 1 ← 回避策（CR のバイト数） |
| `printf '%s' $'\r' \| od -An -c` | `\r`（bash の `$'\r'` そのものは CR になる） |

## 原因

2つが別々に起きる。

1. grep 側: テキストと判断したファイルの CR を外してから比べる（推測。GNU grep の説明書の `-U, --binary` にある MS-DOS・MS-Windows 向けの振る舞いと合い、`-U` を付けると正しく数える）。そのため CR のパターンはどの行にも合わない
2. bash 側: コマンド置換の中の `$'\r'` が、置換の中身を読み直すときに CR を落とし、空のパターンになる（推測。そのまま打つと 0、置換の中では全部の行になる違いから）

## 回避策

1. **CR の数は `tr -cd '\r' < f | wc -c`**（CR のバイト数。CRLF の行の数と同じ）。コマンド置換の中に置いても正しい
2. 行を数えるなら `rg -c $'\r' f` か `grep -U -c $'\r' f`
3. コマンド置換の中に `$'\r'` を書かない

```bash
# NG（そのままなら 0、置換の中なら全部の行）
echo "CR: $(grep -c $'\r' a.md)"

# OK
for f in a.md b.md; do printf '%s CR=%s\n' "$f" "$(tr -cd '\r' < "$f" | wc -c)"; done
```

## 注意

`grep -c` の 0 件は exit 1 になるため、`&&` の後ろが走らない。逆にコマンド置換の中では exit 0 で全部の行の数が出るので、失敗に気づきにくい。同じ MSYS2 の grep の黙った 0 件は `grep_astral-plane-emoji_windows.md` にもある。
