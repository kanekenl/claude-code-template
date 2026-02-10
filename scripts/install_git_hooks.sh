#!/usr/bin/env bash
set -euo pipefail

# リポジトリ内の .githooks を git hook として使う
# （各開発者のローカル設定なので、1回だけ実行すればOK）

git config core.hooksPath .githooks

# 実行権限付与（gitのindex状態に依存せず確実に動かす）
chmod -R +x .githooks

echo "Installed git hooks: core.hooksPath=.githooks"
echo "post-commit: auto create draft PR after first commit"
