# /code-review スキル

<command-name>code-review</command-name>

<description>
PR/差分をレビューし、Plan（仕様）との整合・品質・安全性・運用面の抜けを洗い出す。
レビュー結果は「重要度付きの指摘 + 修正提案 + 追加テスト案」で返す。
</description>

<usage>
/code-review
/code-review <PR URL | ブランチ名 | diff範囲>
</usage>

<instructions>

## 入力（任意）
- `target`: PR URL / PR番号 / ブランチ名 / `main..HEAD` などの差分範囲

## 実行手順

### 1. 仕様（Plan）を特定する
- PR本文に `Plan:` 行があれば、そのファイルを仕様の正とする
- 見つからない場合は、ユーザーに Plan の場所を確認してから続行する

### 2. 差分を把握する
- 変更ファイル一覧、主要な差分、追加/変更/削除の意図を整理する
- 影響範囲（呼び出し元、データ形式、UI、設定、CI）を洗い出す

### 3. 正しさ（仕様一致）を確認する
- Plan の受け入れ条件（Given/When/Then）がコードに反映されているか
- 例外系・境界値・エラーハンドリングが欠けていないか
- 互換性（既存API/DB/設定/入出力）を壊していないか

### 4. テスト観点を確認する
- 変更に対応するテストがあるか（不足なら追加案を出す）
- “壊れやすい実装依存テスト” になっていないか
- 重要な分岐（成功/失敗/権限/空/上限下限）がカバーされているか

### 5. セキュリティ/運用観点を確認する
- 秘密情報（トークン、鍵、個人情報）をログやレスポンスに出していないか
- 入力値検証、権限チェック、エラー内容の露出、パス/URL組み立ての安全性
- ロールバック可能性、設定変更の影響、障害時の挙動（リトライ/タイムアウト）

### 6. PR体裁・自動化前提を確認する（重要）
- PR本文に `Plan:` 行がある（マージ後の plan 自動移動に必要）
- `Closes #<issue>` がある（Issueクローズが意図通りか）
- 破壊的変更があれば説明と移行手順がある

## 出力フォーマット（レビュー結果）
- 概要: 変更の意図を1〜3行
- 指摘（Must/Should/Nice）: 各項目に「理由」「具体的な修正案」
- テスト提案: 追加すべきケースを箇条書き
- リスク: 影響範囲とロールバック案
- 最終判断: approve / request changes / comment

## PRにレビューを残す（任意・明示実行）

この `/code-review` はレビュー文を生成するだけで、GitHubへ自動投稿はしない。
PRに残したい場合は、生成したレビュー文をファイルに保存してから `scripts/post_review.sh` で投稿する。

### コメントとして残す（おすすめ：軽い指摘/メモ）
```bash
bash scripts/post_review.sh comment --file review.md
```

### レビューとして残す（approve/request changes を付けたい時）
```bash
# comment としてレビュー投稿
bash scripts/post_review.sh review --comment --file review.md

# 承認（必要な場合のみ）
bash scripts/post_review.sh review --approve --file review.md

# 変更要求（必要な場合のみ）
bash scripts/post_review.sh review --request-changes --file review.md
```

### PR指定（必要なときだけ）
`--pr` を省略すると「現在のブランチに紐づくPR」を自動検出する。
別PRへ投稿したい場合は `--pr` を指定する。

```bash
bash scripts/post_review.sh comment --pr 123 --file review.md
bash scripts/post_review.sh comment --pr https://github.com/ORG/REPO/pull/123 --file review.md
```

</instructions>