# powershell — Bash ツール経由の文字列では `\\` が `\` に潰れる（正規表現の \k 逆参照エラー、sed 置換のパス欠落）

## 症状
- Claude Code の Bash ツールに渡した command 文字列中の `\\`（バックスラッシュ2連続）が、quoted heredoc（`<<'EOF'`）の中でも `\` 1個になって bash に届く
- 例1: PowerShell 正規表現 `'\\amd64\\kd\.exe$'` をヒアドキュメントで .ps1 に書く → ファイルには `'\amd64\kd\.exe$'` → 実行時「間違った形式の \k<...> 名前付き逆参照です」(Malformed \k<...> named back reference)
- 例2: sed の置換文字列に `C:\\Windows\\Minidump` と書く → sed には `C:\Windows\Minidump` が届き、`\W` `\M` が `W` `M` と解釈されて `C:WindowsMinidump` になる
- 再現: `printf '%s\n' 'x\\y' | od -c` → `x \ y`（素の bash なら `x \ \ y`）。`\s` `\.` `\d` `\(` など「バックスラッシュ＋他の文字」はそのまま届く

## 原因
- Bash ツールがコマンド文字列を渡す層でのアンエスケープ（`\\` → `\`）。bash の heredoc の問題ではない
- Write／Edit ツールの content は潰れない（`x\\y` がそのまま書かれることを od で確認。2026-09-17 Windows 11 / git bash）

## 対処
1. 正規表現・sed 置換にバックスラッシュを書かない: PowerShell は `-like '*\amd64\kd.exe'`（ワイルドカード）、`.EndsWith('\amd64\kd.exe')`、`[IO.Path]::GetFileName()` で比較。sed 置換文字列に Windows パスを入れない
2. どうしても正規表現で必要なら実行時に生成: `[regex]::Escape('\amd64\')`、`[char]92`、.NET regex の `\x5c`
3. `\\` を含むファイルは Write ツールで書く（潰れない）。Bash で書くなら必要な `\\` ごとに `\\\\` と書く（4個→2個になることを `printf '%s\n' 'a\\\\b' | od -c` で確認済み）
