# `pkill -f "<pattern>"` が自分自身にマッチして終了コード 143/15

## 症状
`bash -c 'pkill -f "main.py --port 8188"; ...'` が途中で終了し、後続のコマンドが実行されない（`wsl.exe --exec bash -c` 経由では Exit code 15、シェル経由なら通常 143 = 128+SIGTERM）。

## 原因
`-f` はフルコマンドラインに照合する。パターン文字列を含む `bash -c '...'` 自身のコマンドラインにもマッチし、自分を SIGTERM する。

## 解決
- パターンの1文字をブラケット化: `pkill -f "[m]ain.py --port 8188"`（正規表現は main.py に一致するが、自分のコマンドライン上の文字列 `[m]ain.py` には一致しない）
- または PID を特定して `kill <pid>`（`pgrep -f` の結果から自分の `$$` を除外）

## 観測
2026-10-08 pj_30croquis（WSL で ComfyUI を停止。目的のプロセスは止まったが後続が実行されなかった）

## 関連
- 同じ自己マッチの `pgrep -f` 版: `ssh_remote-job-killed-on-disconnect.md` の備考（待ち合わせの `pgrep -f X` が自分の shell に当たって終わらない）
