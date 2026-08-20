---
name: pj-management
description: プロジェクト管理3ファイル（VISION.md / PROGRESS.md / DECISIONS.md）を初期化・更新する時に invoke する。「pj管理の更新。」と言われた時、セッション開始時に3ファイルが無く初期化する時、Phase の追加/完了・A/B判断の記録・VISIONルールタグの付与/更新・中断スナップショットの記録をする時に使う。各ファイルの記録基準・棲み分け・タグ体系・テンプレート・初期化手順、標準ディレクトリ（_from_owner/_deliverables/_gomi）の作成規約を提供する。
compatibility: OS非依存
metadata:
  author: honokani
  version: 1.1.0
  source: CLAUDE.md「pj管理」節（〜2026-08）を skill 化。CLAUDE.md 側は発動トリガーのみ
---

# pj-management — pj管理3ファイルの記録基準

VISION.md（ポールスター）・PROGRESS.md（実行記録）・DECISIONS.md（判断根拠）の3ファイルでプロジェクトを管理する。CLAUDE.md「pj管理」節が発動トリガー、本 skill が手続き本体。~/.claude 自身の3ファイルは GLOBAL_VISION / GLOBAL_PROGRESS / GLOBAL_DECISIONS.md（`~/.claude/MAINTENANCE.md`）で、記録基準は同一。

## When to use
- セッション開始時に3ファイルが無い → `templates/` から初期化
- 「pj管理の更新。」→ 未反映の変更を本 skill の記録基準で3ファイルへ仕分けて反映
- Phase の開始/完了、既存挙動を変える改修、A/B 判断の発生、VISION ルールの追加やテスト作成、作業の中断
- SKIP: 3ファイルの読込・照合だけで更新が無い場合（Read で足りる）

## 標準ディレクトリ
3ファイル読込・初期化時に、無ければプロジェクト直下に作成する（pj管理対象のプロジェクトだけが対象。無関係の cwd には作らない）。

| ディレクトリ | 用途 | git |
|---|---|---|
| `_from_owner/` | ユーザーから渡されるファイルの置き場。Claude は読む側（編集・生成はしない） | ignore |
| `_deliverables/` | ユーザーと会話するための生成物（レポート・図・検討資料）。プログラム本体は通常の src/app 等の構成に置き、ここには置かない | ignore |
| `_gomi/` | 削除退避先。削除が必要なファイルは削除せず `mv` でここへ移し、中身の削除はユーザーが行う（CLAUDE.md 変更管理） | ignore |

- git 管理プロジェクトでは3つとも .gitignore に追加する（無ければ追記。ユーザーが既に別方針で管理している場合は従う）
- git 追跡済みファイルを `_gomi/` へ退避する時は plain `mv`（`git mv` 不可: ignore 先へ移すため）。履歴上は削除、実体は `_gomi/` に残る

## 3ファイルの棲み分け
| ファイル | 役割 | 更新頻度 |
|---|---|---|
| VISION.md | ポールスター。あるべき姿と「なぜそう作るか」。思想・不変条件 | 低（機能追加・設計判断変更時） |
| PROGRESS.md | 実行記録「何をしたか」。チェックリスト | 高（ステップごと） |
| DECISIONS.md | 判断根拠「なぜAではなくBか」。コードから読めない設計判断のログ | 中（判断発生時） |

## VISION.md
- テンプレート: `~/.claude/skills/pj-management/templates/VISION.md`
- 書く: Why（存在理由）／設計思想・不変条件／入出力情報／コード上の散在情報（キーバインド表等）
- 書かない（コードが正）: ファイル構成・API仕様・座標数値、実装手順（→PROGRESS）、判断経緯（→DECISIONS）
- 設計思想は3層: 全体ルール／機能横断ルール／機能別ルール（必要時のみ）
- ルールタグ: 各ルールにいずれか1つ付与
  - `[philosophy]`: テストで縛れない思想。VISION.md が正
  - `[unittest]` / `[qchecktest]`: テストで検証する制約（タグ名=検証チャネル）。VISION.md には Why、実装はテストコードが正
  - 旧 `[testable]` は廃止。既存ファイルで遭遇したら2タグへの振り分けを提案
- タグ更新規則（テスト作成時）: 作成できなかった項目は理由で分岐
  - 思想ゆえテスト不向き → `[philosophy]` へ更新（根拠を DECISIONS.md へ1行）
  - 対象が未実装なだけ → タグ据置（実装時の1機能1テストループで回収）

## PROGRESS.md
- テンプレート: `~/.claude/skills/pj-management/templates/PROGRESS.md`
- 記録対象: 予定した Phase/タスクの進捗、既存挙動を変える/壊す改修（Phase 未割当でも1行記録）
- 対象外: typo 修正・即興の小変更（git で追える）
- テスト累計数と決定ログ（実行記録）も維持
- Phase 番号はセマンティックバージョニング準拠（初期構想完成=1.0.0）
- 中断スナップショット（割り込み・中断時に記録）:
  ```
  ## Phase: feature-A [中断]
  中断理由 / 再開条件 / 再開起点 / 未決定事項
  ```

## DECISIONS.md
- テンプレート: `~/.claude/skills/pj-management/templates/DECISIONS.md`
- 記録対象: A/B 選択の根拠／一見疑問に思われそうな実装の理由
- 対象外: 一意に決まる作業・typo 修正
- 棲み分け: PROGRESS=何をしたか、DECISIONS=なぜそうしたか

## 初期化手順
1. `templates/{VISION,PROGRESS,DECISIONS}.md` をプロジェクトルートへコピーし `{プロジェクト名}` を置換
2. 既知の情報（README・既存コード・会話）から Why と Phase 0.0.1 を埋める。不明点は空欄のまま提示し、ユーザーに確認する（推測で埋めない）
3. 標準ディレクトリ3つ（前掲）を作成し、git 管理下なら .gitignore に追記

## 注意事項
- `[qchecktest]` の検証チャネルは `qcheck` skill（`tests/*.qcheck.md`）
- 3ファイルは全機能で共有されるため、並行フィーチャーブランチでは衝突しやすい（CLAUDE.md ブランチ運用「基本は逐次1本」の理由）
