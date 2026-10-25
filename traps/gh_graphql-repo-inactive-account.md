# gh — honokani の private リポジトリが「Could not resolve to a Repository」で失敗する（既定のアカウントが show-sai）

## 症状
- `gh issue view 2 -R honokani/kite` などが、`GraphQL: Could not resolve to a Repository with the name 'honokani/kite'. (repository)` で失敗する（exit 1）
- 同じリポジトリへの `git fetch` / `git push` は通る（この PC の git は SSH の鍵を使い、gh のログインとは別）

## 原因
- この PC の gh には show-sai と honokani の 2 つのアカウントが登録されていて、既定（`gh auth status` で `Active account: true` の方）は show-sai。show-sai からは honokani の private リポジトリが見えない
- 既定が show-sai なのは意図どおり（仕事側の C:/ws が show-sai の前提。GLOBAL_DECISIONS 0.2.41）

## 対処
1. `bash ~/.claude/scripts/gh-honokani.sh <gh のサブコマンド>` を使う。`GH_TOKEN=$(gh auth token --user honokani)` を付けて gh を走らせるだけで、トークンは保存しない
   - 例: `bash ~/.claude/scripts/gh-honokani.sh issue view 2 -R honokani/kite`
2. `gh auth switch` で既定を切り替えない（どのディレクトリでも honokani になり、仕事側が壊れる）

## 補足
- このエラー文は `post-bash-traps-pointer.sh` の環境系シグネチャに当たらないので、失敗しても `[traps-hint]` は出ない

## 観測
- 2026-10-25 pj_kite（文脈の要約のあと、それまで付けていた `GH_TOKEN=$(gh auth token --user honokani)` を付け忘れて issue を見ようとした）
