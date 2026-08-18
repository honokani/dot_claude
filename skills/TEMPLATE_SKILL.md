---
name: <skill-name>
description: <いつ・何のために呼ばれるか 1〜3文。triggerキーワードを含めると認識されやすい（例: 「XXして」「YYで」と指示された場合に...）>
compatibility: <OS/ツール依存を明記。OS非依存なら省略可（例: Windows (MINGW64/Git Bash)。uv venvに xxx インストール済み）>
metadata:
  author: <作成者>
  version: <semver、例 1.0.0>
  source: <参考資料があれば。任意>
---

# <Skill Title>

<Skillの概要を1段落。このskillが解決する課題と適用範囲を明示>

## 目的 / When to use

<どんなタスクで呼ばれるか、triggerの例>
<このskillを使うべきでないケース（SKIP条件）も書くと誤発動を減らせる>

## ワークフロー / Usage

<具体的な手順。呼び出し方・入出力・副作用>

## 前提 / Prerequisites

<必要な環境・依存。インストール方法へのリンクや注意点>

## 注意事項 / Caveats

<気をつけるポイント、既知の制限、失敗例>

<!--
  注意: 現状のこの共通フォーマットが最適とは限らない。
  既存 skill（mermaid-to-svg / pdf-reader / slide-writing）の frontmatter形式を
  踏襲して作成しているが、将来レビューで改訂の可能性あり。
-->
