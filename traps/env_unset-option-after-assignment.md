# `env A=1 -u B cmd` が `env: '-u': No such file or directory` になる（オプションは代入より前のみ）

## 症状

```sh
env HOME=/tmp/x -u WSL_DISTRO_NAME zsh -i -c '...'
```

```
env: ‘-u’: No such file or directory
```

配列で `envs=(HOME=... PATH=... "$@")` のように組み立て、呼び出し側から `-u VAR` を渡したときに起きやすい。

## 原因

`env` は最初の非オプション引数（`NAME=VALUE` を含む）でオプション解析を止める。
以降の `-u` は「実行するコマンド名」として扱われ、そのようなファイルが無いので失敗する。

## 解決策

`-u` / `-i` などのオプションを代入より前に置く。

```sh
env -u WSL_DISTRO_NAME HOME=/tmp/x zsh -i -c '...'
envs=("$@" HOME=... PATH=...)   # 呼び出し側の -u を先頭に来るよう連結順を決める
```

## 備考

- GNU coreutils の env（Git for Windows / MSYS2）で確認
- 実例: dotfiles `tests/test_startup_routes.zsh`（2026-10-01, issue #3）
