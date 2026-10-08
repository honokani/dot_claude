# wsl.exe が Wsl/Service/WSAETIMEDOUT で失敗する（エラー文は UTF-16 で化ける）

## 症状
- Git Bash から `wsl.exe -d <distro> --exec ...` が一時的に失敗し、終了コード 127。出力は `�c�}n0n0...` のように化け、末尾に ` W s l / S e r v i c e / W S A E T I M E D O U T` と読める部分がある
- 直後に同じ呼び出しを再実行すると成功した

## 原因
- WSL サービスへの接続のタイムアウト（推測: WSL 内の重い I/O（6GB のモデル取得の書き込み）と重なった）
- wsl.exe 自身のメッセージは既定で UTF-16 のため、Git Bash では化ける

## 対処
1. `WSL_UTF8=1` を付けると wsl.exe のメッセージが読める（`WSL_UTF8=1 MSYS_NO_PATHCONV=1 wsl.exe -d <distro> --exec ...`）
2. 一時的なものなら少し待って再実行。続く場合は `wsl --shutdown` を検討（WSL 内で実行中の処理がすべて止まる点に注意）

## 観測
2026-10-09 pj_30croquis（WSL 内で `ollama pull` 実行中に、別の wsl.exe 呼び出しが失敗）
