# rust_perf-patterns.md — 性能改善で踏んだ borrow / rayon パターン

## [rayon.empty_chunks] par_chunks_mut(0) はパニック
- `chunk_size must not be zero` でパニックする。幅0（空入力）ガードを並列化の前に入れる。
- 逐次の `for py in 0..h { for px in 0..w }` は w=0 でも素通りだったため、並列化した瞬間に顕在化する挙動差。

## [rust.cow_eval] Cow返却の評価関数とmem::takeパターン
- 評価関数が `Cow::Borrowed(&self.field)` を返すと、戻り値が `&self` を保持し続けるため、呼び出し側で別フィールドの `&mut` が取れなくなる。
- 書き込み先バッファを `let mut buf = std::mem::take(&mut self.target);` で一旦move（コピーなし）してからループし、終了後に `self.target = buf;` で戻すと借用が両立する。

## [rust.field_split_borrow] フィールド分割借用とメモ化キャッシュ
- `self.cache.as_ref().unwrap()` のようなフィールド経由の共有借用は、他フィールドへの `&mut`（`&mut self.staging` 等）と共存できる（NLLのフィールド分割借用）。
- ただし `self.method()`（&mut self メソッド呼び出し）とは共存できないため、「①&mut selfでキャッシュを確定 → ②フィールド参照を取得」の2段に分ける。
- メモ化キーは内容ハッシュ（FNV等）にすると、全ミューテーション箇所への無効化通知が不要になる。
