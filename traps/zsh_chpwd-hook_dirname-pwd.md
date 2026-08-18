# zsh の chpwd hook が `$(cd "$(dirname "$0")" && pwd)` を汚染して `command too long` になる

## 症状

zsh で実行/source したスクリプトの定番イディオム

```sh
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
"$SCRIPT_DIR/other.sh"
```

が、次のように失敗する。

```
script.sh:9: command too long
```

（汚染が短いときは `no such file or directory: <ls出力>\n/path/to/other.sh` の形になる）

`echo "$SCRIPT_DIR"` すると `ls -al` の出力の後にパスが出る。

## 原因

zshrc に `chpwd() { ls -al }` のような **`cd` 時に stdout へ出力する hook** があると、
コマンド置換 `$( ... )` の中の `cd` でも hook が発火し、その出力ごと変数に取り込まれる。
zsh は実行するコマンド名が PATH_MAX 以上だと `command too long` を出す。

- 発生条件: hook が定義された環境で走る = 対話 zsh から `source script.sh` した／`~/.zshenv` 経由で zshrc が読まれる、など
- bash には chpwd 相当がないので `bash script.sh` では起きない（bash から呼ばれる子スクリプトは無関係）
- 非対話 `zsh script.sh` は .zshrc を読まないので通常は起きない

## 解決策（推奨順）

1. **`cd` の stdout を捨てる**（bash/zsh 両対応、最小差分）
   ```sh
   SCRIPT_DIR=$(cd "$(dirname "$0")" >/dev/null && pwd)
   ```
   hook は `cd` builtin の内側で呼ばれるので、`cd` へのリダイレクトで hook 出力も遮断される。stderr は残すので cd 自体の失敗は見える。
2. `cd -q`（zsh 専用: chpwd hook を呼ばない）
3. `${0:A:h}`（zsh 専用: サブシェル不要、symlink 解決済み）

`unfunction chpwd` は呼び出し元（source 元）の環境を書き換えるので却下。

## 備考

- 同じ理由で `$(cd dir && some_command)` 全般が hook 出力で汚れうる。値を取るコマンド置換内の `cd` は `>/dev/null` を付ける癖をつける
- 実例: dotfiles `initialize.2.sh` / `link_dotfiles.sh`（2026-08-19、Mac で発覚。zshrc の `chpwd() { _lsl }` が原因）
