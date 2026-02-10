# /tdd スキル（Stitch連携対応版）

<command-name>tdd</command-name>

<description>
Test-Driven Developmentワークフローを強制。planファイルからStitchデザインを自動取得して、
デザインを参照しながら開発できる。
</description>

<usage>
/tdd docs/plans/feature-xxx.md
/tdd （planファイル指定なしでも実行可能）
</usage>

<instructions>

## 実行手順

### 0. 事前準備（CLAUDE.mdに記載の通り）

0. **（初回のみ）git hook を有効化**
   ```bash
   scripts/install_git_hooks.sh
   ```
   - 最初のコミット後に draft PR を自動作成する（既存PRがあれば何もしない）

1. **GitHub issueとブランチを作成**
   ```bash
   scripts/tdd_from_plan.sh docs/plans/feature-xxx.md
   ```
   - issue番号とブランチ名が出力される

2. **docs/progress.mdをアップデート**
   - 変更予定ファイルの一覧
   - エージェント名（他のエージェントからわかるように）
   - GitHub issueへのリンク

3. **重複チェック**
   - 自分の開発ファイルと他のエージェントの開発ファイルに重複がある場合、ユーザーに報告してストップ

### 1. planファイルの読み込みとStitchデザイン取得

planファイルが指定された場合、以下を実行：

1. **planファイルを読み込む**
   - 機能要件、UI仕様を確認

2. **Stitchデザイン情報をチェック**
   - planファイルに「デザイン成果物」セクションがあるか確認
   - `Stitch Project ID` と `Screen ID` を抽出

3. **Stitch MCPからデザインデータを取得**
   ```
   # Screen IDごとにデザインデータを取得
   mcp__stitch__get_screen:
     project_id: {抽出したproject_id}
     screen_id: {抽出したscreen_id}
   ```
   - 取得したデザインデータ（HTMLコード、コンポーネント構造）を参照しながら開発

### 2. TDDサイクル実行

デザインデータを参照しながら、以下のTDDサイクルを実行：

```
RED → GREEN → REFACTOR → REPEAT

RED:      テストを先に書く（失敗することを確認）
GREEN:    最小限のコードでテストを通す
REFACTOR: テストが通る状態を維持しながら改善
REPEAT:   次の機能・シナリオへ
```

#### Step 1: インターフェース定義（SCAFFOLD）

Stitchデザインを参照して：
- コンポーネントのProps型を定義
- 状態管理のインターフェースを定義
- APIレスポンスの型を定義

#### Step 2: テストを先に書く（RED）

```typescript
// 例: コンポーネントテスト
describe('LoginForm', () => {
  it('should render email and password fields', () => {
    // Stitchデザインに基づいたテスト
  })

  it('should show validation error on invalid email', () => {
    // Stitchデザインのエラー状態に基づいたテスト
  })
})
```

#### Step 3: テスト実行（失敗を確認）

```bash
npm test -- --watch
```

#### Step 4: 最小限の実装（GREEN）

Stitchデザインのコードを参考にしながら：
- HTMLコードをReactコンポーネントに変換
- スタイリング（Tailwind CSS等）を適用
- 機能を実装

#### Step 5: リファクタリング（REFACTOR）

テストが通る状態を維持しながら：
- コードの整理
- 共通コンポーネントの抽出
- パフォーマンス最適化

#### Step 6: カバレッジ確認

```bash
npm test -- --coverage
```

**目標: 80%以上のカバレッジ**

### 3. Stitchデザインの活用方法

`mcp__stitch__get_screen`で取得できる情報：

| 情報 | 活用方法 |
|------|----------|
| HTMLコード | React/Next.jsコンポーネントに変換 |
| スタイル情報 | Tailwind CSSクラスに変換 |
| コンポーネント構造 | コンポーネント分割の参考 |
| インタラクション | イベントハンドラの実装参考 |

### 4. 完了時の処理

1. **tmpファイルの削除**
   - ファイル名に「.tmp」がついているファイルを削除

2. **PR作成（Plan: 行を必ず入れる）**
   ```bash
   scripts/tdd_from_plan.sh finish docs/plans/feature-xxx.md
   ```

3. **feature-xxx.mdの移動**
   ```bash
   mv docs/plans/feature-xxx.md docs/plans/finished/
   ```

4. **progress.mdの更新**
   - 作業部分を削除
   - 1行程度に内容を圧縮
   - 例: `動画Duration一括調査 | [feature-video-duration-investigate.md]`

## Stitchデザインがない場合

planファイルにStitch情報がない場合は、通常のTDDワークフローを実行：
- 要件定義に基づいてテストを作成
- デザインはコード実装時に決定

## 関連コマンド

- `/plan` - 機能計画を作成
- `/design` - Stitchでデザインを生成（planにStitch IDが記載される）
- `/build-fix` - ビルドエラーの修正
- `/code-review` - コードレビュー
- `/test-coverage` - カバレッジ確認

</instructions>
