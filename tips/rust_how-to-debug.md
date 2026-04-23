# rust_howtodebug.md — Rust デバッグ手法

## [debug.eprintln] GUIアプリのイベントトレース
- GUIアプリで動作しない機能は `eprintln!` でイベントダンプして原因特定する
- `cargo run 2>debug.log` で stderr をファイルに保存し、後から確認
- 推測で修正を重ねるより、まず1回のデバッグログで事実を確認する
- 毎フレーム出力される値と、特定条件でのみ出力される値を分けると読みやすい
- デバッグ確認後は `eprintln!` を削除すること
