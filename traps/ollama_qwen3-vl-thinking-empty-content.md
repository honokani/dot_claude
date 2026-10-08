# ollama — qwen3-vl:8b の答えが空になる（think: false でも思考で出力上限を使い切る）

## 症状
- Ollama `/api/chat` に `"think": false`・`options.num_predict: 300` で画像の説明を頼むと、`message.content` が空で `done_reason: "length"`・`eval_count: 300`
- `message.thinking` には `<think>` から始まる思考が入っている（`think: false` が効いていない）
- 短い指示だと本文が少し出るが、途中で切れる（2026-10-09、Ollama 0.40.1、`qwen3-vl:8b` Q4_K_M、WSL）

## 原因
- `qwen3-vl:8b`（標準タグ）は思考型（`ollama show qwen3-vl:8b` の Capabilities に `thinking`、default true）。`think: false` を渡しても思考を出力し、出力上限を思考で使い切る（止められない理由は未確認）

## 対処
1. 思考しない版を使う: `ollama pull qwen3-vl:8b-instruct`（Capabilities に thinking が無い）。同じ 5 枚で本文が正常に返った
2. 思考型を使うなら `num_predict` を大きくする。`content` が空で `thinking` だけの応答はエラー扱いにして理由を残す（空のまま進めると原因が分からない）

## 観測
2026-10-09 pj_30croquis（loratrain のキャプション生成。5 枚とも「empty answer」で失敗）
