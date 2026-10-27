# Python uv on Windows — ビルド・キャッシュ問題

## project.scripts使用時

`[project.scripts]` でコマンド登録すると `[build-system]` が必須。
`uv sync` でビルド → `.venv/Scripts/xxx.exe` が生成される。

### pycache問題

- `src/` 配下の `__pycache__/*.pyc` が古いまま残り、ソース変更が反映されない
- `uv sync --reinstall-package <name>` で再ビルドが必要
- ビューワ等が `.exe` をロック中だと再ビルド失敗する

### 対策

- ソース変更後は `uv sync --reinstall-package <name>` を忘れずに実行
- ビューワは先に停止してから sync
- または `uv run python -m module_name` で直接実行（ビルド不要）

## パス形式問題（Bashツール経由）

Claude CodeのBashツールはbash（MSYS2）だが、`uv run python` が起動するのはWindowsネイティブPython。
コード内の文字列リテラルとしてMSYS2形式パス（`/c/Users/...`）を書くと `FileNotFoundError` になる。

- Pythonコード内に埋め込むパスはWindows形式（`C:/Users/...`）で書く
- コマンドライン引数ならMSYS2が自動変換することもあるが、`-c` スクリプト内のリテラルは変換されない

## PATH問題

uv管理のPythonからはシステムのPATHにあるコマンド（`claude` 等）が見えない場合がある。
`config.toml` でフルパスを指定する。

```toml
[claude]
path = "C:/usr/local/claude.cmd"
```

## 隔離モード（`-I`）で日本語の出力が文字化けする

`uv run python -I script.py` で日本語を print すると（リダイレクト先のファイルも）、cp932 で書かれて化ける。化けるだけなら exit 0 なので気づきにくい。cp932 に無い文字（`≈` など）を print すると `UnicodeEncodeError: 'cp932' codec can't encode character` で落ちる。

- 原因: `-I` は `-E` を含むので、`PYTHONIOENCODING`・`PYTHONUTF8` などの環境変数が無視される（前に `PYTHONIOENCODING=utf-8` を付けても効かない）
- 対策: コマンドラインのオプションで UTF-8 モードにする → `uv run python -I -X utf8 script.py`
- スクリプト側で直すなら、先頭で `sys.stdout.reconfigure(encoding="utf-8")`（呼び出し方に依らず効く）
