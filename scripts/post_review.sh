#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'EOF'
PRへレビュー文を投稿する（明示コマンド）

usage:
	bash scripts/post_review.sh comment [--pr <PR番号|PR URL|ブランチ>] [--file <path> | --stdin]
	bash scripts/post_review.sh review  (--comment | --approve | --request-changes) [--pr <PR番号|PR URL|ブランチ>] [--file <path> | --stdin]

examples:
	# review.md をPRへコメント投稿
	bash scripts/post_review.sh comment --file review.md

	# 標準入力からPRへコメント投稿
	cat review.md | bash scripts/post_review.sh comment --stdin

	# approve としてレビュー投稿
	bash scripts/post_review.sh review --approve --file review.md

notes:
	- --pr を省略すると「現在のブランチに紐づくPR」を自動検出します。
	- このスクリプトは PR への自動投稿は行いません（明示実行が必要）。
EOF
}

require_cmd() {
	local cmd="$1"
	command -v "$cmd" >/dev/null 2>&1 || {
		echo "Required command not found: $cmd" >&2
		exit 1
	}
}

get_current_branch() {
	git branch --show-current 2>/dev/null || true
}

infer_pr_target() {
	# 1) 引数で指定されていればそれを返す
	local specified="${1:-}"
	if [[ -n "$specified" ]]; then
		printf '%s\n' "$specified"
		return 0
	fi

	# 2) 現在ブランチのPRを gh で引けるなら、それをターゲットにする
	local branch
	branch="$(get_current_branch)"
	if [[ -z "$branch" ]]; then
		echo "Failed to detect current branch; pass --pr explicitly." >&2
		exit 2
	fi

	# gh pr view <branch> が通るのは、PRが存在する場合
	if gh pr view "$branch" --json number --jq .number >/dev/null 2>&1; then
		printf '%s\n' "$branch"
		return 0
	fi

	echo "No PR found for branch '$branch'. Create PR first or pass --pr explicitly." >&2
	exit 2
}

make_body_file() {
	local file="${1:-}"
	local stdin_flag="${2:-false}"

	if [[ "$stdin_flag" == "true" ]]; then
		local tmp
		tmp="$(mktemp)"
		cat >"$tmp"
		printf '%s\n' "$tmp"
		return 0
	fi

	if [[ -z "$file" ]]; then
		echo "Either --file or --stdin is required." >&2
		exit 2
	fi
	if [[ ! -f "$file" ]]; then
		echo "Body file not found: $file" >&2
		exit 2
	fi

	printf '%s\n' "$file"
}

main() {
	require_cmd gh
	require_cmd git

	local mode="${1:-}"
	if [[ -z "$mode" ]]; then
		usage
		exit 2
	fi
	shift || true

	local pr_arg=""
	local file_arg=""
	local stdin_flag="false"

	local review_action="" # for mode=review: comment|approve|request-changes

	# parse args
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--pr)
				pr_arg="${2:-}"
				shift 2
				;;
			--file)
				file_arg="${2:-}"
				shift 2
				;;
			--stdin)
				stdin_flag="true"
				shift
				;;
			--comment)
				review_action="comment"
				shift
				;;
			--approve)
				review_action="approve"
				shift
				;;
			--request-changes)
				review_action="request-changes"
				shift
				;;
			-h|--help)
				usage
				exit 0
				;;
			*)
				echo "Unknown argument: $1" >&2
				usage
				exit 2
				;;
		esac
	done

	if [[ "$stdin_flag" == "true" && -n "$file_arg" ]]; then
		echo "Use either --stdin or --file (not both)." >&2
		exit 2
	fi

	local pr_target
	pr_target="$(infer_pr_target "$pr_arg")"

	local body_file
	body_file="$(make_body_file "$file_arg" "$stdin_flag")"

	local tmp_cleanup="false"
	if [[ "$stdin_flag" == "true" ]]; then
		tmp_cleanup="true"
		trap 'rm -f "$body_file"' EXIT
	fi

	case "$mode" in
		comment)
			gh pr comment "$pr_target" --body-file "$body_file" >/dev/null
			;;
		review)
			if [[ -z "$review_action" ]]; then
				echo "For review mode, one of --comment/--approve/--request-changes is required." >&2
				usage
				exit 2
			fi
			case "$review_action" in
				comment)
					gh pr review "$pr_target" --comment --body-file "$body_file" >/dev/null
					;;
				approve)
					gh pr review "$pr_target" --approve --body-file "$body_file" >/dev/null
					;;
				request-changes)
					gh pr review "$pr_target" --request-changes --body-file "$body_file" >/dev/null
					;;
				*)
					echo "Unknown review action: $review_action" >&2
					exit 2
					;;
			esac
			;;
		*)
			echo "Unknown mode: $mode" >&2
			usage
			exit 2
			;;
	esac

	local pr_url
	pr_url="$(gh pr view "$pr_target" --json url --jq .url 2>/dev/null || true)"
	if [[ -n "$pr_url" ]]; then
		echo "Posted to PR: $pr_url"
	else
		echo "Posted to PR: $pr_target"
	fi

	# trap は EXIT にぶら下がっているので明示削除は不要
	if [[ "$tmp_cleanup" == "true" ]]; then
		:
	fi
}

main "$@"
