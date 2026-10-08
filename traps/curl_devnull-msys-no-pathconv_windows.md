# MSYS_NO_PATHCONV=1 下で `curl -o /dev/null` が (23) Failure writing output

## 症状
`curl: (23) Failure writing output to destination`（接続・受信は成功している）。

## 原因
Git Bash の curl はネイティブ Windows 実行ファイル。通常は MSYS が `/dev/null` を `NUL` に変換するが、
`wsl.exe` 呼び出し用に `export MSYS_NO_PATHCONV=1`（や `MSYS2_ARG_CONV_EXCL='*'`）を同じシェルで設定していると変換されず、存在しないパスへの書き込みで失敗する。

## 解決
- 変数は `wsl.exe` の行だけに付ける（`MSYS_NO_PATHCONV=1 wsl.exe ...`）。export しない
- または curl 側を `-o NUL` にする
- (23) は「受信後の書き込み失敗」なので、到達性の判定材料としては「接続は成功」と読める

## 観測
2026-10-08 pj_30croquis（WSL のテストサーバへの到達確認中）

## 関連
- 逆向きの罠（変換が効いて壊れる）: `exe_slash-switch-msys-path-conversion_git-bash.md`（`/r` 等のスイッチが Windows パスに化ける → `MSYS_NO_PATHCONV=1` をコマンド単位で）
