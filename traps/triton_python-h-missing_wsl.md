# Triton の実行時ビルドが Python.h なしで失敗する（WSL/Ubuntu・システムPython製venv）

## 症状
ComfyUI 等で初回推論時に `subprocess.CalledProcessError`（`/usr/bin/gcc ... triton/backends/nvidia/driver.c ... -I/usr/include/python3.12`）。
ログ本文は `fatal error: Python.h: No such file or directory`。

## 原因
Triton は実行時に C 拡張（cuda_utils）を gcc でビルドする。venv の元がシステムPython（`/usr/bin/python3.12`）だと、ヘッダは `python3.12-dev` パッケージにあり、素の Ubuntu には入っていない。

## 解決
`sudo apt install python3.12-dev`（WSLなら `wsl -d <distro> -u root` で可）。サーバ再起動は不要、次回実行でビルドが通る。
gcc 自体もない場合は `build-essential` も入れる。

## 観測
2026-10-08 pj_30croquis（Ubuntu 24.04 / torch 2.14.1+cu126 / ComfyUI 0.39.0, Krea2 の CLIPTextEncode で発生）
