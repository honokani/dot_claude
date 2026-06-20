# rust_egui.md — egui/eframe で躓きやすいポイント

## [egui.key_event] Ctrl+C/V/X のキーイベント消費
- egui-winit は `Ctrl+C` pressed を `Event::Copy` に変換する。`key_pressed(Key::C)` は false になる。
- `Ctrl+V` pressed は egui-winit がシステムクリップボードのテキスト読み取りに消費する。テキストがあれば `Event::Paste(text)` を生成するが、画像のみの場合は何も生成されない。
- 結果、`key_pressed(Key::V)` も `Event::Paste` も false になる。
- **対策**: `Event::Key { key: Key::V, pressed: false, modifiers, .. } if modifiers.ctrl` でキーリリースを検出する。
- `Ctrl+X` も同様に `Event::Cut` に変換される。
- `Event::Copy` は正常に発火するので、Ctrl+C は `Event::Copy` で検出可能。

## [egui.consume_key] consume_key の注意
- `input_mut(|i| i.consume_key(Modifiers::COMMAND, Key::V))` も Ctrl+V pressed が既に消費されているため false を返す。
- consume_key は「まだ消費されていない Key イベント」にしか効かない。

## [egui.key_event] Ctrl+A 等、他のCtrl+キーの検出
- Ctrl+C/V/X は特殊処理されるが、Ctrl+A/N/Z/Y 等は `Event::Key { pressed: true }` として普通に来る。
- 検出方法の使い分け:
  - Ctrl+C → `Event::Copy` で検出
  - Ctrl+X → `Event::Cut` で検出
  - Ctrl+V → `Event::Key { pressed: false }` (リリース) で検出（唯一の手段）
  - Ctrl+A/N/Z/Y 等 → `Event::Key { pressed: true, modifiers.ctrl }` で検出可能

## [egui.selectable_label] SelectableLabel vs label
- `ui.label()` はクリックイベントを取れない。レイヤーリスト等でクリック選択が必要なら `SelectableLabel` を使う。
- フォルダ名も同様。`label()` だと選択不可になる。

## [egui.guard_pattern] ツール別ガード分離パターン
- 全ツールを一括ブロックする `pen_blocked` のような変数に条件を追加すると、選択ツール等まで巻き添えでブロックされる。
- 「描画不可だが選択は可能」のような細かい制御が必要な場合、ガード条件は各 `Tool::*` 分岐の内部で個別に判定する。

## [egui.cfg_not_test] `#[cfg(not(test))]` とフィールドアクセス
- egui依存のフィールド（`tabs: Vec<CanvasTab>`, `active_tab: usize` 等）を `#[cfg(not(test))]` で囲むと、そのフィールドにアクセスするコードにも同じガードが必要。
- 漏れるとテストビルドで `no field 'tabs' on type` エラーになる。
- pure fn（`best_dual_layout_size` 等の計算関数）にはガード不要。egui型に依存しない関数は分離しておくとテストしやすい。

## [egui.prev_frame_rect] 前フレームのRectを使う遅延パターン
- eguiのイベント処理は描画前に行われるため、そのフレームの `canvas_rect` はまだ確定していないことがある。
- 前フレームの `canvas_rect` を `last_canvas_rect: Option<egui::Rect>` として保存し、イベント処理時にはそれを参照することで、レイアウト未確定の問題を回避できる。
- 「遅延処理キュー」を作るより単純で、カウントダウン等の待ち時間がある場合は十分間に合う。

## [egui.partial_texture] テクスチャの部分更新（0.27で利用可）
- `TextureHandle::set_partial([x, y], ColorImage, options)` で矩形領域のみGPU転送できる（`epaint::ImageDelta::partial` のラッパー）。
- ペイント系でストローク中に毎フレーム全面 `set()` すると全面clone＋全面転送になる。フレーム毎の変化bboxを追跡して `set_partial` に切り替えると転送量が領域比で減る。
- 部分画像はピクセルバッファから行ごとに `extend_from_slice` で集めて作る。

## [egui.repaint_after] 周期アニメの省電力repaint
- マーチングアンツ等は毎フレーム `request_repaint()` ではなく `request_repaint_after(Duration)` で「次の状態変化タイミング」のみ要求する。位相計算: `next = period - (time % period)`。
- 入力中はeguiが自動でrepaintするため、ドラッグ追従はrepaint_afterでも壊れない。

## [egui.pointer_trail] ポインタ入力のフレーム量子化対策
- `i.pointer.interact_pos()` はフレームに1点だけ。高レートのペン/マウス入力は `i.events` の `Event::PointerMoved(pos)` に全件残っている。
- 描画ツールでは全件をストローク処理に供給すると速い線の忠実度が上がる（60Hz量子化の解消）。
