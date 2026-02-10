# プロジェクトルール

## 作業ディレクトリ
- すべての作業はこのプロジェクトフォルダ内で行うこと  
- プロジェクトフォルダ外のファイルを変更しないこと  
- 新規ファイルの作成もプロジェクトフォルダ内に限定すること  

## 言語
- 日本語を使用すること  
- 思考過程（thinking）も日本語で行うこと  
- コメント、ドキュメント、コミットメッセージはすべて日本語で記述すること  
- ユーザーへの応答も日本語で行うこと  

## 進捗管理
- 全体の進捗ファイル：`docs/progress.md`  
  - 詳細計画がどこに記載されているかもかく  
- 詳細企画：`docs/plans/feature-xxx.md`  
  - この企画を読んだら、なるべくファイルを読み込まずに実行できるレベルに計画する
  - コードマップの確認が必要な場合はここを確認する
- コードの構造：/CODEMAPS/***.md
- 重要：新セッション開始時は、docs/codemap.md と docs/progress.md を読んで、続きから作業を再開して
- /tdd で作業をスタートしたら、まずdocs/progress.mdをアップデートして。


## update-docsを使った場合
- docs/progress.mdも同時にアップデートして。


## /planが終わったあと
- 別セッションでtddで実装するので、docs/plans/feature-xxx.mdを作成したら終了


## /design の使い方

UIデザインが必要な機能の場合、planファイルを指定してデザインを生成する：

```
/design docs/plans/feature-xxx.md
```

**実行内容:**
1. planファイルからUI要件を抽出
2. Stitch MCP経由でデザインを生成
3. `assets/ui/{feature-name}/` に成果物を保存:
   - `*.png` - UIデザイン画像
   - `*.html` - HTMLプレビュー（オプション）
4. planファイルに「デザイン成果物」セクションを追加して合意対象を固定

**推奨ワークフロー:**
1. `/plan` で機能計画を作成
2. `/design docs/plans/feature-xxx.md` でデザイン生成
3. デザインレビュー・修正
4. `/tdd` で実装開始


## /tddの開始直後

### （初回のみ）リポジトリ初期セットアップ
リポジトリを新規作成した直後は、mainやdevelopブランチが存在しない場合がある。
以下の手順で確認・作成すること：

```bash
# 現在のブランチとリモートの状態を確認
git branch -a

# mainブランチが存在しない場合（初回コミットがまだない場合）
# 1. 最低限のファイルをコミットしてmainを確立する
git add README.md .claude/CLAUDE.md
git commit -m "chore: リポジトリ初期セットアップ"
git push -u origin main

# 2. developブランチを作成
git checkout -b develop
git push -u origin develop
```
- mainブランチ：本番リリース用。直接コミットしない
- developブランチ：開発統合用。featureブランチはここから切る
- featureブランチ作成時は `develop` から切ること

### （初回のみ）git hook を有効化
```bash
scripts/install_git_hooks.sh
```
- 最初のコミット後に draft PR を自動作成する（既存PRがあれば何もしない）

### 1. GitHub issueを作成
```bash
gh issue create --title "機能名" --body "planファイルへのリンクと概要"
```
- issue番号を控える（例: #11）

### 2. ブランチを作成
```bash
git checkout develop
git pull origin develop
git checkout -b feat/issue-{番号}-{機能名}
```
- 例: `feat/issue-11-pastel-pop-design`
- 必ず`develop`ブランチから切ること

### 3. docs/progress.mdをアップデート
  - どのファイルを変更するかの一覧も記載
  - エージェント名として、どのエージェントが稼働しているかをかく（他のエージェントからわかるようにする）
  - 作成したGitHub issueへのリンクも記載
- 重要：作業の重複を防止するため、もし自分の開発ファイルと、他のエージェントの開発ファイルに重複がある場合、ユーザーに報告してストップして

## tddが終わった場合

### 1. tmpファイルの削除
- ファイル名に「.tmp」がついているファイルを削除する

### 2. コミット作成
```bash
git add <変更ファイル>
git commit -m "feat: 機能の説明 #issue番号"
```

### 3. プルリクエストを作成
```bash
scripts/tdd_from_plan.sh finish docs/plans/feature-xxx.md
```
 - PR本文に `Plan: docs/plans/feature-xxx.md` 行が必ず入る（マージ後の自動移動で使用）
 - PR本文に `Closes #issue番号` を必ず含めること（mainマージ時にIssueが自動クローズされる）
 - PRのマージ先は `develop` ブランチにすること

### 4. mainへのマージ（リリース時）
- developからmainへのPRを作成してマージする
- **重要:** develop→main のPR本文にも `Closes #issue番号` を含めること
  - feature→develop のPRに書いた `Closes` はdevelopマージでは自動クローズされない（GitHubはデフォルトブランチへのマージ時のみ自動クローズする）
- 手動でCloseする場合: `gh issue close {番号}`

### 5. ドキュメント更新
- feature-xxx.mdを`docs/plans/finished/`に移動
- progress.mdをアップデート（作業部分を削除し、1行に圧縮）
  - 例：動画Duration一括調査 | [feature-video-duration-investigate.md]