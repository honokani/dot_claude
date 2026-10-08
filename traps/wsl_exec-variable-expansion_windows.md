# `wsl.exe -d X -- bash -c '...$var...'` で変数が空になる → `--exec` を使う

## 症状
`for t in git curl; do $t --version; done` が `bash: line 1: --version: command not found` になる等、ループ変数・`$var` が空。
`$(whoami)` のような値は一見動くので気づきにくい。

## 原因
`wsl.exe ... -- <cmd>` はコマンド行を連結してディストリの既定シェル（`$SHELL -c`）に渡す。外側シェルが先に `$var` を展開し、引用も崩れる。

## 解決
`wsl.exe -d X --exec bash -c '<script>'` — 既定シェルを介さず引数をそのまま渡す。
Git Bash から呼ぶときは `MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*'` も付ける（`/` 始まりの引数が Windows パスに変換されるのを防ぐ。ただし export は避ける → `curl_devnull-msys-no-pathconv_windows.md`）。

## 観測
2026-10-08 pj_30croquis（新ディストリのツール確認ループ）
