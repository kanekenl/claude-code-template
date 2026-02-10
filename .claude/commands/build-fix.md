# /build-fix スキル

<command-name>build-fix</command-name>

<description>
ビルド/CI失敗を再現し、原因を特定して最小の修正で復旧する。
</description>

<usage>
/build-fix
/build-fix <ログ | エラー文 | CIリンク>
</usage>

<instructions>

## 実行手順

### 1. 失敗状況を確定する
- どのコマンド（lint/test/build/typecheck）で落ちているか
- ローカル再現の可否、再現手順、失敗ログの核心行を抽出する

### 2. 原因を切り分ける
- 依存関係（lockfile/バージョン差分）
- 型/構文エラー、import解決、環境差（Node/OS）
- テストのフレーク/順序依存、タイミング依存

### 3. 最小修正で直す
- まず “失敗を止める最小の修正” を入れる
- その後、必要なら根本原因（設計・境界条件・契約）まで戻って改善する

### 4. 検証する
- 同じコマンドで再実行し、成功を確認する
- 影響が大きい場合は関連コマンドも実行する（lint/typecheck/全テストなど）

### 5. 仕上げ
- 何が原因で、どう直したかをPR本文/コメントに短く残す
- 再発防止が必要ならテストやチェックを追加提案する

</instructions>