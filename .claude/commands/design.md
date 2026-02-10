# /design スキル

<command-name>design</command-name>

<description>
planファイルを参照してStitch MCP経由でUIデザインを生成するスキル。
生成されたデザインは `assets/ui/` に保存され、planファイルに成果物パスが記録される。
</description>

<usage>
/design docs/plans/feature-xxx.md
</usage>

<instructions>

## 引数

- `planFile`: デザイン対象のplanファイルパス（必須）
  - 例: `docs/plans/feature-login.md`

## 実行手順

### 1. planファイルの読み込み

指定されたplanファイルを読み込み、以下の情報を抽出する：
- 機能名・概要
- UI要件（画面構成、コンポーネント、インタラクション）
- デザイン仕様（あれば）

### 2. Stitch MCPでデザイン生成

Stitch MCPを使用してUIデザインを生成する：

```
# 各画面・コンポーネントに対して生成
stitch_generate_image:
  - prompt: planファイルから抽出したUI要件に基づくプロンプト
  - style: "ui-design"（または適切なスタイル）
```

### 3. 成果物の保存

生成されたデザインを以下の構造で保存：

```
assets/ui/
├── {feature-name}/
│   ├── {screen-name}.png      # UIデザイン画像
│   ├── {screen-name}.html     # HTMLプレビュー（オプション）
│   └── README.md              # デザイン説明
```

### 4. planファイルの更新

planファイルに「デザイン成果物」セクションを追加。**重要: Stitch IDを必ず記載すること（/tddで参照するため）**

```markdown
## デザイン成果物

生成日: YYYY-MM-DD
Stitch Project ID: {project_id}

| 画面名 | Screen ID | URL | 説明 |
|--------|-----------|-----|------|
| ログイン画面 | abc123def | https://stitch.google.com/... | メインログイン画面 |
| エラー状態 | xyz789ghi | https://stitch.google.com/... | バリデーションエラー表示 |
```

**注意**: Screen IDは`mcp__stitch__generate_screen_from_text`の戻り値から取得できる。
このIDがあれば、`/tdd`実行時に`mcp__stitch__get_screen`でデザインデータを直接取得できる。

### 5. 完了報告

以下の内容をユーザーに報告：
- 生成されたデザインファイルの一覧
- プレビューへのリンク
- planファイルの更新内容

## 注意事項

- Stitch MCPが利用できない場合は、ユーザーに設定方法を案内する
- 既存のデザインファイルがある場合は、上書き前に確認を求める
- 生成に失敗した場合は、エラー内容を明確に報告する

</instructions>