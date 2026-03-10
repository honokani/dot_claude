# rust_windows.md — Windows 環境での Rust 開発で躓きやすいポイント

## [windows.exe_lock] ビルド中に exe が使用中エラー
- `cargo build` で `failed to remove file *.exe` / `アクセスが拒否されました (os error 5)` が出る場合、対象の exe が実行中。
- アプリを閉じてから再ビルドする。コードの問題ではない。

## [windows.arboard] arboard クリップボード操作
- `arboard::Clipboard::new()` は毎回新しいインスタンスを作る必要がある（所有権で drop される）。
- 画像クリップボード (`set_image` / `get_image`) は Windows では正常動作するが、`get_image` は画像がなければ `Err` を返す（テキストのみの場合等）。
- `ImageData.bytes` は RGBA u8 のフラットバイト列。`Cow<[u8]>` で渡す。
