# bash から PowerShell を呼ぶときの `$` 展開トラップ

## 前提: Bashツールの実体はbash

Claude Codeの環境情報に「Shell: PowerShell」と表示されていても、**Bashツールはbash（MSYS2）で動く**。
`Get-ChildItem` 等のコマンドレットを直接投げると `command not found` (exit 127)。
PowerShellを使いたい場合は下記の通り `powershell -Command`/`-File` 経由で呼ぶ。

## 症状

Claude Code (Windows) の Bash ツールで `powershell -Command "..."` を叩くと、PowerShell スクリプト内の `$_` や `$env:TEMP` などが **bash 側で先に展開されて空文字列になり**、PowerShell パーサがエラーを返す。

エラー例:
```
= : 用語 '=' は、コマンドレット...の名前として認識されません
+  = :TEMP;  = (Get-ChildItem  -Recurse ...
```
（`$env:TEMP` が空文字列に、`$sz = ...` の `$sz` も空文字列になり `= ...` だけが残った状態）

## 原因

bash がダブルクォート内の `$` を環境変数として展開してから PowerShell に文字列を渡す。
PowerShell の自動変数 (`$_`, `$PSItem`)、環境変数アクセス (`$env:NAME`)、ローカル変数すべてが影響を受ける。

## 解決策（推奨順）

### 1. `.ps1` ファイルに書いて `-File` で実行（最も確実）

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\path\to\script.ps1"
```

bash は文字列展開せず、PowerShell が自前でファイルを読む。`$_`, `$env:`, パイプ内変数すべて素のまま通る。
日本語コメントや正規表現も問題なし（UTF-8 BOM 付きで保存しなくても通る）。

### 2. シングルクォートで囲む（短い 1 行コマンド向け）

```bash
powershell -NoProfile -Command 'Get-ChildItem $env:TEMP | %{ $_.Name }'
```

ただし PowerShell スクリプト内でシングルクォート文字列を使えなくなるトレードオフあり。

### 3. `$` をバックスラッシュエスケープ

```bash
powershell -Command "Get-ChildItem \$env:TEMP | %{ \$_.Name }"
```

複雑になると視認性が落ちるので、長いスクリプトは案 1 へ。

## 派生のハマりどころ

- **PowerShell スクリプトを自分が消す Temp 配下に置かない**: `$env:TEMP` を消すスクリプトの出力先が `$env:TEMP` だと、スクリプト実行中に Claude Code 自身の出力ファイル (`C:\Users\<user>\AppData\Local\Temp\claude\...`) も消えて、bash 経由の戻り値が読めなくなる。スクリプトは `~/.claude/workspace_for_claude/` に置く。
- **日本語混じり Regex のパースエラー**: 行末バッククォート継続行 + 日本語 + `match` を組み合わせるとパーサが文字化けして死ぬことがある。ASCII のみで `-match` を書く方が安全。
- **管理者権限が必要なコマンド** (`DISM /Online /Cleanup-Image`, `reagentc /info` 等) は Claude Code からは実行不可。ユーザーに管理者ターミナルでの実行を依頼する。
