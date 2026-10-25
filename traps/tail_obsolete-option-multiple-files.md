# tail — `tail -2 a b`（ファイルが複数）が「option used in invalid context -- 2」で失敗する

## 症状
- `tail -2 file1 file2` が `tail: option used in invalid context -- 2` で失敗する（exit 1）。ファイルが 1 つなら通る
- 長いコマンドの最後に確認として付けると、前のコマンドが成功していても全体が exit 1 になる（バックグラウンド実行の知らせが failed になる）

## 原因
- `-2` は行数を数字だけで書く昔の書き方。GNU tail（coreutils）は、この書き方をファイルが 1 つ（か無し）のときだけ受け付ける

## 対処
- `tail -n 2 file1 file2` と書く。`head` も `head -n 2` にそろえる

## 観測
- 2026-10-25 pj_kite（シミュレーションを裏で 2 本回し、最後に確認として `tail -2 main.txt extra.txt` を付けた。計算は 2 本とも終わっていたが、知らせは failed になった）
