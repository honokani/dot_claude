# 回収フロー

## 1. pull conflict

SessionStart で `git pull --rebase --autostash` 中に conflict したケース。

### 手順
1. `git -C ~/git_clone/dot_claude status` で conflict ファイル特定
2. conflict マーカー（`<<<<<<<`, `=======`, `>>>>>>>`）を削除しながら該当ファイルを手動編集
3. `git -C ~/git_clone/dot_claude add <file>`
4. `git -C ~/git_clone/dot_claude rebase --continue`
5. 必要なら `git push`

### 中断したい場合
`git -C ~/git_clone/dot_claude rebase --abort` で rebase 前の状態に戻す。

### read-only モードの clone で「pull --ff-only 失敗」が出た場合
rebase は行われないので conflict 状態にはならない。原因は (a) その clone にローカル commit/未保存変更がある、(b) remote に到達できない、のどちらか。
(a) は read-only 環境では発生させない運用（MAINTENANCE.md「read-only モード」）。持ち帰る価値のある変更なら内容を控えたうえで `git -C <clone> reset --hard origin/master`（ローカル commit と未保存変更は消える）で clone を remote に揃える。

## 2. push rejected (behind)

ローカルのpushが remote のcommitと衝突し reject されたケース。

### 手順
1. `git -C ~/git_clone/dot_claude pull --rebase --autostash`
2. conflict が出たら上記「1. pull conflict」のフローへ
3. 問題なければ `git -C ~/git_clone/dot_claude push`

## 3. gitleaks pre-commit 検出（commit失敗時）

commit が pre-commit フックでブロックされたケース。

### 未pushの場合（通常ケース）
1. gitleaks の出力を確認（ファイル名・行番号・パターンID）
2. 該当行を修正:
   - **APIキー直書き → 環境変数化**
   - **取引先名 → 伏字/仮名**
   - **.credentials等ファイル → .gitignore追加**
3. 再度 `git add` → `git commit`

### 誤検知の場合
1. `dot_claude/.gitleaks.toml` に allowlist 追加 or ルール調整
2. `git add` → `git commit` で再試行

### 緊急bypass（原則使用禁止）
`git commit --no-verify` で pre-commit フックをスキップ可能だが、機微情報漏洩リスクが高いので通常利用禁止。使う場合は直後に gitleaks 手動フルスキャン。

## 4. gitleaks 検出を見逃してpushしてしまった（重大事故）

### 即時対応（数分以内）
1. **キーの無効化/rotation** を最優先（APIキーなら管理画面で即revoke）
2. GitHub リポジトリ → Settings → Secret Scanning で状況確認

### 履歴書換（他マシンとの協調が必要）
1. 混入commitを特定:
   ```
   git log -S "<leaked_string>" --all
   ```
2. `git filter-repo` で履歴書換:
   ```
   pip install git-filter-repo
   echo "<leaked_string>==><REMOVED>" > /tmp/replacements.txt
   git -C ~/git_clone/dot_claude filter-repo --replace-text /tmp/replacements.txt
   ```
3. `git -C ~/git_clone/dot_claude push --force-with-lease`
4. **全マシンで再clone**（古いローカルリポジトリは破棄）
5. gitleaks の rule に該当パターンを追加して再発防止

### 注意
- 履歴書換後も GitHub のキャッシュ・fork には残る可能性
- Public repo の場合は即 private 化してから作業、その後 public 戻すか判断
- キー rotation が最優先、履歴書換は二の次
