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

## PATH問題

uv管理のPythonからはシステムのPATHにあるコマンド（`claude` 等）が見えない場合がある。
`config.toml` でフルパスを指定する。

```toml
[claude]
path = "C:/usr/local/claude.cmd"
```
