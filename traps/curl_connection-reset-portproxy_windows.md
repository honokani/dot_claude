# localhost:PORT が Connection was reset（netsh portproxy がポートを先取りしている）

## 症状
WSL 内のサーバ（`127.0.0.1:PORT` 待受）に Windows から接続すると `curl: (56) Recv failure: Connection was reset`。WSL 内からの curl は成功する。

## 原因
Windows 側で iphlpsvc（svchost）が `netsh interface portproxy` のルール `0.0.0.0:PORT → <WSL IP>:PORT` で同じポートを待ち受けている。
localhost 宛てが WSL の localhost 転送ではなく portproxy に入り、WSL IP 宛てに転送 → 127.0.0.1 待受のサーバには届かずリセット。

## 確認
- `netstat -ano | grep ":PORT "` → 持ち主PID、`tasklist //SVC //FI "PID eq <pid>"` → `iphlpsvc` なら portproxy
- `netsh interface portproxy show all`（Git Bash では iconv せず `| cat` で読む。cp932→utf8 変換すると化ける）

## 解決
ユーザ既存の portproxy は消さず、別ポートを使う（WSL2 NAT の localhost 転送は 127.0.0.1 待受でも届く）。
既存ルールを使いたい場合はサーバを `0.0.0.0` で待ち受ける（＝LAN公開になる点に注意）。

## 観測
2026-10-08 pj_30croquis（ComfyUI 8188 → 8189 に変更）
