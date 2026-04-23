# Python HTTPServer on Windows — Ctrl+C問題

## 問題

`HTTPServer.serve_forever()` はWindowsでCtrl+Cが効かない場合がある。

## 根本原因

ChromaDB(onnxruntime)がリクエストハンドラ内で初期化されるとシグナル処理が壊れる。
スレッドにしても、遅延importにしても、リクエスト処理中にonnxruntimeが初期化されればアウト。

以下は全て効果なし:
- `signal.signal(signal.SIGINT, handler)`
- `SetConsoleCtrlHandler` (ctypes)
- `try/except KeyboardInterrupt` on `serve_forever()`
- daemonスレッド

## 解決策

1. **ChromaDB/onnxruntimeの全importとget_collection()をサーバ起動前に完了させる（トップレベルimport + serve()冒頭で初期化）**
2. `serve_forever()` を使わず `handle_request()` + timeout ポーリングループにする
3. リクエストハンドラ内で遅延importしない

```python
# 重い初期化はサーバ起動前に完了させる（スレッド不要）
run_backfill()

server = HTTPServer((host, port), Handler)
server.timeout = 1

try:
    while True:
        server.handle_request()
except KeyboardInterrupt:
    os._exit(0)
```

## 注意

- `os._exit(0)` はプロセスを即座に終了する
- `sys.exit()` だと終了しない場合がある
- `server.timeout` を設定しないと `handle_request()` がブロックしてCtrl+Cが効かない

## subprocess + Windows

- `subprocess.run` で `shell=True` + `.cmd` ファイル経由だと `text=True` でcp932デコードされる
- 対策: バイナリモード (`stdout=subprocess.PIPE`) + `.decode("utf-8")`
- プロンプトは引数ではなく `input=prompt.encode("utf-8")` でstdin経由で渡す（shellのクォート問題回避）
