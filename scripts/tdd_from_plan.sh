#!/usr/bin/env bash
set -euo pipefail

BASE_BRANCH="${BASE_BRANCH:-develop}"

usage() {
	cat <<'EOF'
usage:
	scripts/tdd_from_plan.sh docs/plans/xxx.md
	scripts/tdd_from_plan.sh start  docs/plans/xxx.md
	scripts/tdd_from_plan.sh finish docs/plans/xxx.md
	scripts/tdd_from_plan.sh open-pr [--draft] [--no-edit-existing] [docs/plans/xxx.md]

env:
	BASE_BRANCH=develop
EOF
}

MODE="start"
if [[ "${1:-}" == "start" || "${1:-}" == "finish" || "${1:-}" == "open-pr" ]]; then
	MODE="$1"
	shift
fi

PLAN_PATH="${1:-}"

get_current_branch() {
	git branch --show-current
}

infer_issue_number_from_branch() {
	local branch="$1"
	if [[ "$branch" =~ ^feat/issue-([0-9]+)- ]]; then
		printf '%s\n' "${BASH_REMATCH[1]}"
		return 0
	fi
	return 1
}

get_plan_path_for_branch() {
	local branch="$1"
	git config --local --get branch."$branch".tddPlanPath 2>/dev/null || true
}

title_from_plan() {
	local plan_path="$1"
	local title_line
	title_line="$(sed -n 's/^#[[:space:]]\{1,\}//p' "$plan_path" | head -n 1 || true)"
	local title="${title_line:-$(basename "$plan_path" .md)}"
	printf 'feat: %s\n' "$title"
}

ensure_clean_worktree() {
	if [[ -n "$(git status --porcelain)" ]]; then
		echo "Working tree is not clean. Commit/stash changes before running finish."
		exit 1
	fi
}

start_mode() {
	if [[ -z "$PLAN_PATH" ]]; then
		usage
		exit 2
	fi

	local title
	title="$(title_from_plan "$PLAN_PATH")"

	# Issue作成（本文はplan丸ごと）
	local issue_url issue_number
	issue_url="$(gh issue create --title "$title" --body-file "$PLAN_PATH" --json url --jq .url)"
	issue_number="$(echo "$issue_url" | awk -F/ '{print $NF}')"

	# ブランチ名生成
	local slug branch
	slug="$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed -E 's/^feat:[[:space:]]*//; s/[^a-z0-9]+/-/g; s/^-+|-+$//g' | cut -c1-40)"
	branch="feat/issue-${issue_number}-${slug}"

	git checkout "$BASE_BRANCH"
	git pull --ff-only
	git checkout -b "$branch"

	# 後続（hook等）でplanパスを参照できるように、ブランチローカル設定として保持
	git config --local branch."$branch".tddPlanPath "$PLAN_PATH"

	echo "Issue: #$issue_number"
	echo "Branch: $branch"
	echo "Next: implement TDD, commit, then run:"
	echo "  scripts/tdd_from_plan.sh finish $PLAN_PATH"
}

render_pr_body() {
	local plan_path="$1"
	local issue_number="$2"
	cat <<EOF
## 概要
（ここに変更内容を記載）

Plan: $plan_path

Closes #$issue_number

## 仕様の満たし方
- 

## テスト
- 実行コマンド:
  - ``
- 結果:
  - [ ] ✅ pass
  - [ ] ❌ fail（理由: ）

## 影響範囲 / リスク
- 影響範囲:
- 互換性:
- リスク:

## ロールバック手順
- 

## チェックリスト
- [ ] PR本文に `Plan:` 行がある
- [ ] Plan（仕様）と実装が一致している（ズレがあれば Plan を更新済み）
- [ ] CIがすべて成功している
- [ ] エッジケース（境界値/エラー）に配慮した
- [ ] セキュリティ観点の見落としがない
- [ ] ドキュメント更新が必要なら実施した
EOF
}

open_pr_mode() {
	local draft="false"
	local no_edit_existing="false"
	local arg
	while [[ $# -gt 0 ]]; do
		arg="$1"
		case "$arg" in
			--draft)
				draft="true"
				shift
				;;
			--no-edit-existing)
				no_edit_existing="true"
				shift
				;;
			-*)
				echo "Unknown option: $arg"
				usage
				exit 2
				;;
			*)
				break
				;;
		esac
	done

	local branch
	branch="$(get_current_branch)"
	if [[ -z "$branch" ]]; then
		echo "Failed to detect current branch."
		exit 1
	fi
	if [[ "$branch" == "$BASE_BRANCH" ]]; then
		echo "You are on base branch ($BASE_BRANCH). Checkout a feature branch first."
		exit 1
	fi

	local issue_number
	if ! issue_number="$(infer_issue_number_from_branch "$branch")"; then
		echo "Cannot infer issue number from branch name: $branch"
		echo "Expected: feat/issue-<number>-..."
		exit 1
	fi

	local plan_path="${1:-}"
	if [[ -z "$plan_path" ]]; then
		plan_path="$(get_plan_path_for_branch "$branch")"
	fi
	if [[ -z "$plan_path" ]]; then
		echo "Plan path is required (or run start mode first to store it)."
		exit 2
	fi

	local title
	title="$(title_from_plan "$plan_path")"

	local body_file
	body_file="$(mktemp)"
	trap 'rm -f "$body_file"' EXIT
	render_pr_body "$plan_path" "$issue_number" >"$body_file"

	# PR作成にはリモートブランチが必要。upstream未設定なら -u で push。
	if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
		git push
	else
		git push -u origin "$branch"
	fi

	local pr_number=""
	if pr_number="$(gh pr view "$branch" --json number --jq .number 2>/dev/null)"; then
		if [[ "$no_edit_existing" == "true" ]]; then
			echo "PR already exists (#$pr_number). Skipping edit."
			return 0
		fi
		gh pr edit "$pr_number" --title "$title" --body-file "$body_file"
		echo "Updated PR: #$pr_number"
		return 0
	fi

	local create_args=(--base "$BASE_BRANCH" --head "$branch" --title "$title" --body-file "$body_file")
	if [[ "$draft" == "true" ]]; then
		create_args+=(--draft)
	fi
	gh pr create "${create_args[@]}"
	echo "Created PR for $branch"
}

finish_mode() {
	ensure_clean_worktree

	if [[ -z "$PLAN_PATH" ]]; then
		usage
		exit 2
	fi
	open_pr_mode "$PLAN_PATH"
}

case "$MODE" in
	start) start_mode ;;
	finish) finish_mode ;;
	open-pr) open_pr_mode "$@" ;;
	*) usage; exit 2 ;;
esac