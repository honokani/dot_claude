#!/bin/bash
# dot_claude の issue/API 操作を honokani 名義に固定する gh ラッパー（MAINTENANCE.md 三層ルール）
# 背景: gh には git の includeIf に相当するディレクトリ別アカウント切替が無く、
#       既定アカウントが別名義の環境では issue 作成者がズレる（issue #10）
# 前提: この環境の gh に honokani アカウントが登録済み（gh auth login -h github.com -w）
#       トークンは都度 keyring から取得し、ファイルに保存しない
TOKEN=$(gh auth token --user honokani 2>/dev/null)
if [ -z "$TOKEN" ]; then
    echo "ERROR: gh に honokani アカウントが未登録です。環境タイプで対応が分かれます（MAINTENANCE.md 三層ルール）:" >&2
    echo "  - 登録してよい環境: gh auth login -h github.com -w（honokani でログイン）" >&2
    echo "  - GitHub 認証を置かない環境（read-only 運用）: 起票せず、issue 文面を報告に残して他環境から立てる" >&2
    exit 1
fi
exec env GH_TOKEN="$TOKEN" gh "$@"
