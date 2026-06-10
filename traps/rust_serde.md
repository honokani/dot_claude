# rust_serde.md — serde/bincode で躓きやすいポイント

## [serde.derive_chain] Serialize/Deserialize の derive 連鎖
- bincode や serde_json でシリアライズする構造体は、フィールドに含まれる全ての型にも `Serialize, Deserialize` が必要。
- 追加し忘れるとコンパイルエラーになるが、エラーメッセージが深いジェネリクスの中に埋もれて原因特定しづらい。
- 新しい型を作ったら、将来シリアライズ対象になる可能性があるなら最初から derive しておくと楽。

## [serde.bincode_compat] bincode のバージョン互換
- bincode 1.x はデフォルトで可変長エンコーディング。フィールド追加・削除で既存ファイルが読めなくなる。
- ファイルフォーマットのバージョニングが必要なら、先頭にマジックバイト+バージョン番号を入れる。
