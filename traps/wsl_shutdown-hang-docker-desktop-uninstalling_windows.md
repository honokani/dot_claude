# WSL — `wsl --shutdown` も返らず、Docker Desktop が docker-desktop を登録できない（Uninstalling のまま・RegisterDistro/0x8000000d）

## 症状
- Docker Desktop のエンジンが 500 を返す（`request returned 500 Internal Server Error for API route and version http://%2F%2F.%2Fpipe%2FdockerDesktopLinuxEngine/...`）。C: の空きが数 GB まで減っていた
- `docker desktop restart` が 5 分たっても返らない。その後 Docker Desktop は止まり（`Could not retrieve status. Is Docker Desktop running?`）、エンジンの pipe も無くなる（`open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified.`）
- `wsl -l -v`・`wsl --shutdown` が返らない。プロセスは `wslservice.exe`・`vmmemWSL`・`wslrelay.exe`・`wsl.exe` が残る
- WSL のサービスを止めてから Docker Desktop を起動すると「Unexpected WSL error」:
  ```
  deploying "docker-desktop": importing WSL distro "このディストリビューションのインストール、アンインストール、または変換が進行中です。
  エラー コード: Wsl/Service/RegisterDistro/0x8000000d"
  ```
- `wsl -l -v` が `docker-desktop  Uninstalling  2`。レジストリ `HKCU\Software\Microsoft\Windows\CurrentVersion\Lxss\{GUID}` の `State` が `0x4`、`BasePath` の `%LOCALAPPDATA%\Docker\wsl\main` は空

## 原因（推測）
- Docker Desktop の再起動が docker-desktop の登録解除を始めたところで WSL が固まり、そのままサービスを強制終了したので、登録が「アンインストール中」で残った

## 対処
1. **固まった WSL のサービスを管理者で止める**（`wsl --shutdown` が返らないとき）。管理者でないシェルからは UAC を出して止める。.ps1 は ASCII だけで書く（`powershell_bomless-ps1-cp932_windows.md`）
   ```powershell
   Start-Process -FilePath 'taskkill.exe' -ArgumentList '/F', '/IM', 'wslservice.exe' -Verb RunAs -Wait -PassThru -WindowStyle Hidden
   ```
   WSL の中で動いているもの（ほかのディストリビューションも）は全部止まる。止めたあと `tasklist` で wsl・vmmem のプロセスが消えたことを確かめる
2. **途中で止まった登録解除を済ませる**: `wsl --unregister docker-desktop`（「この操作を正しく終了しました」）。消えるのは `%LOCALAPPDATA%\Docker\wsl\main` の登録だけで、Docker が起動のときに作り直す。イメージなどのデータは `%LOCALAPPDATA%\Docker\wsl\disk\docker_data.vhdx` にあり、触らない
3. Docker Desktop を起動する（`"/c/Program Files/Docker/Docker/Docker Desktop.exe"`）。docker-desktop が作り直されて Running になり、約 15 秒でエンジンが応答した

## 補足
- **起動待ちに `docker info` の終了コードを使わない。** エンジンにつながらなくても `docker info --format '{{.ServerVersion}}'` は 0 で終わる（「応答した」と誤判定した）。`docker version --format '{{.Server.Version}}'` の出力が空でないかで判定する
- `wsl.exe` の出力は UTF-16LE なので、bash では `| iconv -f UTF-16LE -t UTF-8` で読む。`reg.exe`・`taskkill` の出力は cp932

## 観測
- 2026-11-05、Windows 11・WSL（Store 版の wslservice.exe）・Docker Desktop（server 28.3.0）。pj_rat で ECR へ push する前に、Docker のエンジンが 500 になっていた
