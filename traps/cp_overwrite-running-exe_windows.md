# cp: 実行中 exe の上書きで Device or resource busy (Windows)

## 症状
```
cp: cannot create regular file 'app/back/game.exe': Device or resource busy
```
デプロイスクリプトで実行バイナリを `cp` 上書きしようとすると失敗する。パイプで grep フィルタしていると失敗が握り潰されて「配置されたはずなのに古いまま」になりがち（mtime 確認で発覚）。

## 原因
Windows は実行中の exe のファイル内容をロックする（上書き・削除不可）。ただし**同一ボリューム内のリネーム（mv）は可能**。

## 対処
リネーム退避方式にする。実行中プロセスは退避された旧ファイルのハンドルを持ち続けるので動作に影響しない。

```bash
rm -f "${DST}.old" 2>/dev/null || true   # 前回退避分の掃除（まだ実行中なら失敗してよい）
if ! cp "$SRC" "$DST" 2>/dev/null; then
  mv -f "$DST" "${DST}.old"              # 実行中でもリネームは通る
  cp "$SRC" "$DST"
fi
```

## 補足
- スクリプトの失敗を grep で絞った出力越しに見ると気づけない。デプロイ検証は成果物の mtime / ハッシュで行う
