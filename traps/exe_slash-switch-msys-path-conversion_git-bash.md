# exe — git bash から Windows 実行ファイルに `/r` `/t` などのスラッシュ スイッチを渡すと MSYS がパスに変換して壊れる

## 症状
- `/c/Windows/System32/shutdown.exe /r /t 180 /c "..."` が使い方（usage）表示だけ出して終了コード 1 で終わる（表示は cp932 のため文字化け）。`/r` などが `C:/Program Files/Git/r` のような Windows パスに変換されて渡るため
- 対象: shutdown / reg / sc / net / icacls など `/switch` 形式の引数を取る Windows 実行ファイル全般

## 原因
- MSYS2（git bash）の引数パス変換。`/` で始まる引数を Windows パスへ書き換える

## 対処
1. コマンド単位で変換を止める: `MSYS_NO_PATHCONV=1 /c/Windows/System32/shutdown.exe /r /t 180 /c "..."`（確認済み 2026-09-17）
2. スイッチを `//r` のように二重スラッシュで書く（`/r` として渡る）
3. `powershell -Command "shutdown /r /t 180"` 経由（PowerShell 側では変換されない）
