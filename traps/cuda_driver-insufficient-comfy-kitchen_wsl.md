# CUDA driver version is insufficient（ComfyUI の TextGenerate / comfy_kitchen の flash_attention_decode）

## 症状
ComfyUI の TextGenerate（Qwen3-VL など LLM によるテキスト生成）が
`RuntimeError: CUDA error: CUDA driver version is insufficient for CUDA runtime version` で落ちる。画像生成は動く。
起動ログには `You need pytorch with cu130 or higher to use optimized CUDA operations` の警告が出ている。

## 原因
comfy_kitchen の `flash_attention_decode` カーネルが新しい CUDA ランタイム向けで、古いドライバ（例: 560.94 = CUDA 12.6）では動かない。
`comfy_kitchen.flash_attention_decode_is_available()` は True を返すため、`comfy/text_encoders/llama.py` は通常経路へフォールバックしない。

## 確認
トレースバックの末尾が `comfy_kitchen/flash_attention.py ... flash_attention_decode`。

## 解決
1. 根本: NVIDIA ドライバを CUDA 13 対応版へ更新する
2. 回避: 起動時に `comfy_kitchen.flash_attention_decode_is_available = lambda *a, **k: False` を当てる（llama.py が通常の KV キャッシュ経路に戻る）。custom_nodes に置く小さなモジュールで、ドライバが CUDA 13 未満のときだけ当てる
   - ドライバの CUDA 版は `ctypes.CDLL("libcuda.so.1").cuDriverGetVersion(ctypes.byref(v))` で取る（12060 = 12.6）。torch 2.14 には `torch._C._cuda_getDriverVersion` がない

## 観測
2026-10-08 pj_30croquis（WSL Ubuntu 24.04、torch 2.14.1+cu126、ComfyUI 0.39.0、comfy-kitchen 0.2.37）。回避ノードの実例: pj_30croquis `comfy_nodes/croquis_compat/`
