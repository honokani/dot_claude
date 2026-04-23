# rust_const_design.md — const 定数設計パターン

## [const.formula_base] マジックナンバーを式で定義する
- レイアウト定数は基本サイズ（`SWATCH_LG`, `INDENT_W` 等）の式で定義する。
- 例: `LAYER_OBJ_W = SWATCH_LG * 3.0 + INDENT_W * 3.0` (= 180.0)
- 「なぜその値か」が式から読み取れるため、後で比率変更する際に基本値だけ変えれば連動する。
- `VAR_W = (SWATCH_LG * 3.0 + INDENT_W * 3.0) / 2.0` のように他の定数からの導出も可。

## [const.remainder_calc] 可変幅を残りから自動計算する
- 固定列の合計を `const fn sum()` で計算し、ウィンドウ幅から引いて可変列幅を得る。
- `CANVAS_W = WINDOW_W - sum(BOTTOM_FIXED) - ITEM_SPACING_X * N - PANEL_MARGIN * 2.0`
- 列を追加/削除しても `BOTTOM_FIXED` 配列を更新するだけで可変列が自動調整される。

## [const.dynamic_override] const定数 + 動的レイアウトの併用
- `settings_size.rs` の const 定数はデフォルトウィンドウサイズでの初期値。
- `panel.rs` で毎フレーム `ui.available_width()` / `ui.available_height()` から再計算し `layout_*` フィールドに格納。
- const値はフォールバックおよびウィンドウリサイズ前の初期レイアウトとして機能する。

## [const.sum_helper] const fn sum ユーティリティ
- Rust の const fn ではイテレータが使えないため、while ループで実装する。
```rust
const fn sum(vals: &[f32]) -> f32 {
    let mut i = 0; let mut s = 0.0;
    while i < vals.len() { s += vals[i]; i += 1; }
    s
}
```
- 配列の `.len()` も const 文脈で使える。
