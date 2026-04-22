# mirror / kareido エフェクト実装計画

## Context

エフェクトに4種（mirror, mirror_shift, kareido, kareido_shift）を追加する。
いずれもApplyレイヤーのピクセルを直線/半直線で分割し、基準面のミラーまたはコピーで埋める。

## 仕様まとめ

### 共通
- 入力レイヤー: 0、適用レイヤー: 1、変数入力: 2
- 変数x: ×360 → 基準角度（度）
- 変数y: 本数（mirror 1〜11、kareido 2〜12）
- EffectParams内にanchor座標を保持（mirrorは通過点+2本目オフセット、kareidoは中心点）
- 非基準面は基準面のピクセルで**上書き**（source_overではない）

### mirror / mirror_shift
- N本の**等間隔平行直線**。角度は変数x×360で決定
- 1本目（基準線）: D&Dで位置移動。EffectParams内にanchor (f32,f32) 保持
- 2本目: D&Dで1本目からの距離を設定 → 間隔が決まる。EffectParams内にspacing (f32) 保持
- 3本目以降: 等間隔で自動配置
- **本数1**: 基準線の片側全体が鏡写し
- **本数2以上**: 任意の隣接2線間が基準面。左右に交互にミラー(mirror)/コピー(mirror_shift)がN本目まで続く
- mirror: 交互にミラー・コピー、mirror_shift: コピーのみ

### kareido / kareido_shift
- N本の**等角度半直線**。共通端点（中心）はD&Dで移動。EffectParams内にcenter (f32,f32) 保持
- 角度は変数x×360が基準角度。N本が360/N度間隔
- 隣接2半直線間の扇面が基準面。残りの扇面は交互にミラー(kareido)/コピー(kareido_shift)
- kareido: 交互にミラー・コピー、kareido_shift: コピーのみ

## 変更対象ファイル

- `src/canvas.rs` — EffectParams拡張、add_*関数、eval_port_inner/eval_effect_with_data、ピクセル変換ロジック
- `src/ui/panel.rs` — ComboBox追加、エフェクト描画UI（線の可視化、D&Dハンドル）

## EffectParams拡張 (canvas.rs)

```rust
pub enum EffectParams {
    None,
    HueShift { degree: f32 },
    Alpha { factor: f32 },
    Mirror { anchor: (f32, f32), spacing: f32 },       // 新規
    MirrorShift { anchor: (f32, f32), spacing: f32 },   // 新規
    Kareido { center: (f32, f32) },                     // 新規
    KareidoShift { center: (f32, f32) },                // 新規
}
```

## add_* 関数 (canvas.rs, LayerGraph impl)

4つ追加。パターンはadd_alphaと同じ:
- input_count: 0, var_input_count: 2
- name: "mirror" / "mirror_shift" / "kareido" / "kareido_shift"
- デフォルト: anchor=(canvas中心は不明なので(0,0)), spacing=50.0, center=(0,0)

## eval_port_inner / eval_effect_with_data (canvas.rs)

既存パターンに従い、name matchに4分岐追加:

```
"mirror" | "mirror_shift" => {
    let source = apply_data?;
    let angle = var_values.get(0).copied().unwrap_or(0.0) * 360.0;  // 度
    let count_raw = var_values.get(1).copied().unwrap_or(0.0);
    let count = (count_raw * 10.0 + 1.0).round().clamp(1.0, 11.0) as usize;
    let (anchor, spacing) = match &params {
        EffectParams::Mirror { anchor, spacing } => (*anchor, *spacing),
        EffectParams::MirrorShift { anchor, spacing } => (*anchor, *spacing),
        _ => ((0.0, 0.0), 50.0),
    };
    let is_shift = name == "mirror_shift";
    apply_mirror(&source, w, h, angle, count, anchor, spacing, is_shift)
}
"kareido" | "kareido_shift" => {
    let source = apply_data?;
    let angle = var_values.get(0).copied().unwrap_or(0.0) * 360.0;
    let count_raw = var_values.get(1).copied().unwrap_or(0.0);
    let count = (count_raw * 10.0 + 2.0).round().clamp(2.0, 12.0) as usize;
    let center = match &params {
        EffectParams::Kareido { center } => *center,
        EffectParams::KareidoShift { center } => *center,
        _ => (0.0, 0.0),
    };
    let is_shift = name == "kareido_shift";
    apply_kareido(&source, w, h, angle, count, center, is_shift)
}
```

### 変数y→本数の変換
- mirror: `(y * 10 + 1).round().clamp(1, 11)` — y=0→1本, y=1.0→11本
- kareido: `(y * 10 + 2).round().clamp(2, 12)` — y=0→2本, y=1.0→12本

## ピクセル変換ロジック (canvas.rs、純粋関数)

### apply_mirror()
```rust
fn apply_mirror(
    source: &[[f32; 4]], w: usize, h: usize,
    angle_deg: f32, count: usize,
    anchor: (f32, f32), spacing: f32,
    shift_only: bool,
) -> Option<Vec<[f32; 4]>>
```

1. 角度からunit法線ベクトル `n = (cos(angle+90°), sin(angle+90°))` を算出
2. 各ピクセルについて: anchorからの符号付き距離 `d = dot(pos - anchor, n)` を計算
3. count==1: d<0のピクセルを鏡写し（shift_onlyなら何もしない — いや、shift_onlyでcount==1は意味がないので基準面そのまま）
4. count>=2: `band = floor(d / spacing)` でどのバンドにいるか判定
   - band==0: 基準面（そのまま）
   - band奇数: shift_only → コピー、!shift_only → ミラー
   - band偶数(≠0): コピー
   - バンド番号が count-1 を超えたら処理しない（元のピクセルを維持）
5. ミラー: d' = -d (法線方向に反転)、コピー: d' = d - band*spacing でソース座標を計算
6. bilinear_sampleでサンプリング

### apply_kareido()
```rust
fn apply_kareido(
    source: &[[f32; 4]], w: usize, h: usize,
    angle_deg: f32, count: usize,
    center: (f32, f32),
    shift_only: bool,
) -> Option<Vec<[f32; 4]>>
```

1. 扇の角度 = 360° / count
2. 各ピクセルについて: centerからの角度 `theta = atan2(y-cy, x-cx)` を算出
3. 基準角度からの相対角度で、どの扇にいるか判定: `sector = floor((theta - base_angle) / sector_angle)`
4. sector==0: 基準面（そのまま）
5. sector奇数: shift_only → コピー回転、!shift_only → ミラー反転
6. sector偶数(≠0): コピー回転
7. ミラー: 基準面の対称角度位置からサンプル、コピー: 回転でソース座標を計算
8. bilinear_sampleでサンプリング

## UI (panel.rs)

### ComboBox追加
エフェクト追加ドロップダウンに4項目追加:
```
"mirror", "mirror_shift", "kareido", "kareido_shift"
```

### 線の可視化とD&Dハンドル
エフェクト区画（LAYER_CON_W）内のエフェクトフレーム描画時に、
mirror/kareidoのエフェクトが存在する場合のみキャンバス上に線を重ね描画。

**Phase分割の都合上、線の可視化・D&Dは後のPhaseで実装**:
- Phase 1: エフェクト登録 + ピクセル変換ロジック（変数のみで制御、anchorはデフォルト値）
- Phase 2: キャンバス上の線描画 + D&Dでanchor/spacing/center操作

## 実装フェーズ

### Phase 0.12.0-1: エフェクト登録・基本ロジック
- EffectParams拡張（4バリアント追加）
- add_mirror / add_mirror_shift / add_kareido / add_kareido_shift
- ComboBoxに4項目追加
- eval_port_inner / eval_effect_with_data に分岐追加
- apply_mirror / apply_kareido 純粋関数実装
- var_values→params デフォルトフォールバック
- **検証**: エフェクト追加→変数接続→値を変えてミラー/万華鏡が動作

### Phase 0.12.0-2: キャンバス上の線描画
- エフェクト区画でmirror/kareidoのanchor/center/spacingを表示
- キャンバス上にc2sで線をオーバーレイ描画（選択中のエフェクトのみ）
- mirror: N本の平行線、kareido: N本の半直線

### Phase 0.12.0-3: D&Dハンドル操作
- 基準線（1本目）のD&D: anchor移動
- mirror 2本目のD&D: spacing変更
- kareido 中心点のD&D: center移動
- EffectParams内の値をリアルタイム更新

### Phase 0.12.0-4: テスト・ポリッシュ
- apply_mirror / apply_kareido の単体テスト
- count境界値テスト (1, 11, 2, 12)
- Serialize/Deserialize対応（EffectParams拡張分）

## 検証方法
- `cargo test` — 全テスト通過 + 新規テスト
- `cargo run` — ミラーエフェクト適用で左右対称描画、万華鏡で放射対称
