# claude-code-template

Claude（/plan→/tdd）運用を前提にした、Issue/PR/Plan管理のテンプレートです。

- Plan（仕様）は `docs/plans/*.md`
- PR本文に `Plan: docs/plans/<file>.md` を必ず入れる（自動化が依存）
- 最初のコミット後に **draft PR を自動作成**（ローカル git hook）
- PRが `develop` にマージされたら、Plan を `docs/plans/finished/` へ **自動移動**（GitHub Actions）

---

## 前提（必要なもの）

- Git
- GitHub CLI: `gh`
  - 例: macOS なら `brew install gh`
- `gh` の認証
  - `gh auth login`

> NOTE: PR/Issue 操作は `gh` を使います。認証していないと各スクリプトが失敗します。

---

## セットアップ（初回だけ）

### 1) リポジトリを clone

```bash
git clone <YOUR_REPO_URL>
cd claude-template
```

### 2) git hook を有効化（推奨）

```bash
bash scripts/install_git_hooks.sh
```

これにより `core.hooksPath` が `.githooks` になり、最初のコミット後に draft PR を自動作成します。

- hook 実体: `.githooks/post-commit`
- インストーラ: `scripts/install_git_hooks.sh`

### 3) GitHub CLI を認証

```bash
gh auth login
```

---

## 全体的な開発フロー（推奨）

「Plan（仕様）→ 実装 → PR → develop へマージ → Plan 自動整理」の流れです。

### 0. Plan を作る（仕様の正）

- Plan 置き場: `docs/plans/feature-xxx.md`
- ここが仕様の single source of truth（PRレビュー/自動化が参照します）

### 1. `/tdd` 開始（Issue とブランチ作成）

Plan を元に Issue 作成→ブランチ作成までを自動化します。

```bash
bash scripts/tdd_from_plan.sh start docs/plans/feature-xxx.md
# 省略形（start がデフォルト）
bash scripts/tdd_from_plan.sh docs/plans/feature-xxx.md
```

この時点で以下を行います：
- `gh issue create` で Issue を作成（本文は Plan 全文）
- `feat/issue-<番号>-<slug>` ブランチを作成
- ブランチに Plan パスを保存（後述の hook が参照）

### 2. 実装（TDD）→ コミット

普段どおりに実装し、適切にコミットします。

```bash
git add <files>
git commit -m "feat: <変更内容> #<issue番号>"
```

#### draft PR 自動作成（hook）について

`bash scripts/install_git_hooks.sh` を実行済みの場合：
- **最初のコミット後**に `.githooks/post-commit` が動きます
- 条件を満たすと draft PR を作成します
  - ブランチ名が `feat/issue-<number>-...`
  - `tdd_from_plan.sh start` で Plan パスが保存済み
  - まだ PR が存在しない

> 失敗してもコミット自体は成功する設計です（hook は常に `exit 0`）。

### 3. PR を作る / 更新する（明示）

hook で draft PR ができていれば、そのまま push するだけで OK です。

まだ PR がない/本文を更新したい場合は、以下で明示的に作成/更新できます：

```bash
bash scripts/tdd_from_plan.sh open-pr --draft
```

完了時（クリーンな作業ツリーが必須）は、こちらの方が分かりやすいです：

```bash
bash scripts/tdd_from_plan.sh finish docs/plans/feature-xxx.md
```

`finish` は内部で `open-pr` を呼び、PR本文に必ず以下を入れます：

- `Plan: docs/plans/feature-xxx.md`
- `Closes #<issue>`

### 4. レビュー（/code-review）

`/code-review` は「レビュー文を生成する」コマンドで、**自動投稿はしません**。
PRに残したい場合は、レビュー文をファイルに保存してから投稿します。

- 投稿（コメント）:

```bash
bash scripts/post_review.sh comment --file review.md
```

- 投稿（レビュー: approve/request changes/comment）:

```bash
bash scripts/post_review.sh review --comment --file review.md
bash scripts/post_review.sh review --approve --file review.md
bash scripts/post_review.sh review --request-changes --file review.md
```

### 5. develop へマージ（人が実施）

マージは通常どおり GitHub 上で行います（自動マージは入れていません）。

### 6. Plan の自動移動（GitHub Actions）

PR が `develop` にマージされると、GitHub Actions が PR本文の `Plan:` 行を読み取り、該当 Plan を `docs/plans/finished/` に移動します。

- workflow: `.github/workflows/move-plan-on-merge.yml`

> つまり、`Plan:` 行が無い PR は Plan 自動移動ができません。

---

## コマンド/スクリプト詳細

### `scripts/tdd_from_plan.sh`

Plan 起点で Issue/ブランチ/PR を作るためのスクリプトです。

- `start <plan>`
  - Issue 作成 → ブランチ作成 → ブランチに Plan パス保存
- `open-pr [--draft] [--no-edit-existing] [plan]`
  - push（upstream 自動設定）
  - PR があれば更新（`--no-edit-existing` なら更新しない）
  - PR がなければ作成（`--draft` 対応）
- `finish <plan>`
  - 作業ツリーが clean であることを要求
  - `open-pr <plan>` を実行（PR作成/更新）

環境変数：
- `BASE_BRANCH`（デフォルト `develop`）

### `scripts/post_review.sh`

レビュー文を PR へ投稿する「明示コマンド」です。

- `comment` … PRコメントとして投稿
- `review` … PRレビューとして投稿（`--comment/--approve/--request-changes`）

PR指定：
- `--pr` を省略すると「現在ブランチの PR」を自動検出
- `--pr 123` / `--pr <PR URL>` も可能

本文指定：
- `--file review.md`
- `--stdin`（標準入力）

### `bash scripts/install_git_hooks.sh`

- `git config core.hooksPath .githooks` を設定
- `.githooks` 配下に実行権限を付与

### `.githooks/post-commit`

- 最初のコミット後に draft PR を自動作成
- 既に PR がある場合は何もしない
- 失敗してもコミット成功を優先（常に `exit 0`）

---

## PR本文のルール（重要）

PR本文に **必ず** 次を含めます：

- `Plan: docs/plans/<file>.md`
- `Closes #<issue-number>`

テンプレ: `.github/pull_request_template.md`

---

## Claude コマンド（.claude/commands）

このテンプレートは Claude のスラッシュコマンドを前提にしています。

- `/tdd`: `.claude/commands/tdd.md`
- `/design`: `.claude/commands/design.md`
- `/code-review`: `.claude/commands/code-review.md`
- `/build-fix`: `.claude/commands/build-fix.md`
- `/test-coverage`: `.claude/commands/test-coverage.md`

---

## トラブルシュート

### PRが自動作成されない

- `bash scripts/install_git_hooks.sh` を実行したか
- `gh auth status` が通るか
- ブランチ名が `feat/issue-<number>-...` になっているか
- `bash scripts/tdd_from_plan.sh start <plan>` で開始したか（Plan パス保存が必要）

### Plan がマージ後に finished に移動しない

- PR本文に `Plan:` 行があるか（先頭が `Plan:` の行）
- `docs/plans/...` のパスが正しいか
- workflow が有効か: `.github/workflows/move-plan-on-merge.yml`
