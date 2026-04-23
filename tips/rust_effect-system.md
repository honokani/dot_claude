# rust_effect_system.md — エフェクトシステム設計パターン

## [effect.add_new] 新しいエフェクトを追加する手順
1. `EffectParams` に新バリアント追加（例: `Alpha { factor: f32 }`）
2. `add_*()` メソッド追加（`input_count`, `var_input_count` を正しく設定）
3. `eval_port_inner` / `eval_effect_with_data` の両方に評価分岐追加
4. 未接続VarInputのデフォルト値マッチアームに追加
5. panel.rs のエフェクト追加UI（ComboBox）に選択肢追加
6. テスト追加

## [effect.var_normalize] 変数値の正規化
- 変数の値域は 0.00〜1.00（正規化済み）で統一する。
- エフェクト側で必要な範囲に変換する（例: HueShift は `value * 360.0` で度数に変換）。
- UIのステップは 0.01、表示は `{:.2}`（小数2位）。
- 丸め: `(new_v * 100.0).round() / 100.0` で0.01単位に正規化。

## [effect.apply_model] Apply ポートの設計
- エフェクトは高階関数: InputとVarInputでfix後、Applyポートでレイヤーデータを引き込み加工する。
- 1レイヤーにつき1 Apply制約（`Effect.Apply → LayerObj.Input`）。
- Applyなしエフェクト（input_count=0, var_input_count=N）は変数のみで動作する。
