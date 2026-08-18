# MAINTENANCE.md — ~/.claude 自体の保守ルール

対象: CLAUDE.md・MAINTENANCE.md・MODEL_ROUTING.md・skills/・traps/・tips/・scripts/hooks・settings.json 等、~/.claude 配下の変更。
読まれ方: dot_claude リポジトリで作業するセッションには `.claude/CLAUDE.md`（import shim）経由で自動読込。他プロジェクトから ~/.claude 配下を編集する時は、CLAUDE.md「~/.claude 自体の変更」の指示で本ファイルを Read してから着手。

## 実体と同期
- 実体は git repo `dot_claude`（このWindows機では `C:/git_clone/dot_claude`。位置は `readlink ~/.claude/CLAUDE.md` の親ディレクトリ）。~/.claude へは `link_claude.sh` がトップレベル項目を個別に symlink（dotfile は対象外）。git 操作は実体 repo 側で行う
- 編集前に `git pull`、編集後に `git push`（他環境へ即時反映）。SessionEnd hook の auto-push は失敗防止ネットであり、毎回の push を省略しない
- 主作業は `feature/<機能>-<要旨>` ブランチで隔離（CLAUDE.md ブランチ運用と同じ）。~/.claude/CLAUDE.md は実体への symlink なので、ブランチ checkout 中に始まる新規セッションはブランチ版の CLAUDE.md を読む（試運転として使える／戻すには master を checkout）
- トップレベル項目を追加・移動・削除したら各環境で `bash link_claude.sh` を実行（新規リンク作成と、dot_claude を指す壊れたリンクの掃除。冪等）
- 削除系コマンドは permission deny + PreToolUse hook で多層ブロックされており Claude からは実行できない。移動は `git mv`、削除が必要な変更はユーザーに依頼する

## 記録（GLOBAL_* 3ファイル）
- GLOBAL_VISION.md（設計思想）／GLOBAL_PROGRESS.md（変更ログ）／GLOBAL_DECISIONS.md（判断根拠）。記録基準は pj管理（`pj-management` skill）と同一
- ~/.claude 作業時・CLAUDE.md 変更時に更新する

## ルールの剪定
- 行動ルールは「防ぐ失敗」とセットで管理。防いでいた失敗が直近セッションで再現しなくなったルールは、GLOBAL_DECISIONS.md に記録して実験的に外す（根拠はモデルの自己申告でなく観測実績）

## 仕組みの所在
- hook 本体は `scripts/hooks/`（settings.json に登録）。設計思想は `GLOBAL_VISION.md`、自動管理（pull/push・gitleaks）の設計と復旧手順は `features/auto_manage/`
- latest_cache: SessionStart hook（session-start-cache.sh）がマーカー探索→鮮度判定→注入→old/ 移動まで全自動処理。Claude 側の手動確認は不要
- traps 配信: Bash 失敗時に post-bash-traps-pointer.sh が [traps-hint] を注入。照合キー=traps ファイル名の主題語（`traps/README.md`）
