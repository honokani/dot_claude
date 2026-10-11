# wsl — `wsl.exe --exec fstrim` が `execvpe(fstrim) failed: No such file or directory`（/usr/sbin のコマンドを名前で呼べない）

## 症状
- `wsl.exe -d <distro> -u root --exec fstrim -av` が `WSL (304 - Relay) ERROR: CreateProcessCommon:817: execvpe(fstrim) failed: No such file or directory`、終了コード 1（2026-10-11、WSL 3.0.1.0、Git Bash から）
- `/usr/sbin` にあるコマンドを名前で渡すと同じになる（`sysctl` でも確認。root でも一般ユーザーでも）。`/usr/bin` のコマンド（`printenv` 等）は名前で動く

## 原因
- `--exec` では、WSL（Relay）がコマンドを探して直接起動する。起動した先の PATH（`--exec printenv PATH`）には `/usr/sbin` が入っているのに見つからないので、探すときはその PATH を使っていない
- 推測: Relay 自身の PATH（無ければ glibc の既定 `/bin:/usr/bin`）で探している

## 対処
- フルパスで渡す: `MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' wsl.exe -d <distro> -u root --exec /usr/sbin/fstrim -av`（Git Bash では `/` 始まりの引数の変換を止める。`wsl_exec-variable-expansion_windows.md` と同じ）
- またはシェルを通す: `wsl.exe -d <distro> -u root --exec bash -lc 'fstrim -av'`（シェルは中の PATH で探す）

## 観測
2026-10-11 pj_loratrain（WSL の VHDX を圧縮する前の fstrim）
