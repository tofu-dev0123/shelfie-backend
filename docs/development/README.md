# 開発ドキュメント

実装するときの作法をまとめる。**設計判断の理由は書かない** — それは
[アーキテクチャ決定記録（ADR）](../decisions/README.md) の担当。

## まず読むもの

実装に入る前にこの2本を読む。

| ドキュメント | 内容 |
|---|---|
| [実装ガイドライン](./implementation-guidelines.md) | 実装フロー・アーキテクチャ制約・**禁止事項**・命名ルール・コメント規約 |
| [ディレクトリ構成](./directory.md) | 各層の責務・呼び出し関係・**どのレイヤーに書くかの判断基準** |

## そのほか

| ドキュメント | 内容 |
|---|---|
| [テスト](./testing.md) | spec の書き方（Model / Service / Request）・外部 API のモック |
| [バリデーション処理](./validation.md) | Model バリデーションから `ErrorHandler` までの流れ |
| [定数管理](./constants.md) | エラーコード・メッセージ・定数の置き場 |
| [ログ設計](./logging.md) | lograge の設定・ログレベルの使い分け・実装例 |
| [Docker 環境構築](./docker.md) | サービス構成・環境変数・セットアップ手順 |
| [インフラ](../../infra/README.md) | CloudFormation の命名規則・テンプレートの適用手順 |

## 環境構築からの流れ

```
1. Docker 環境構築          docker.md
2. 実装ガイドラインを読む    implementation-guidelines.md
3. どの層に書くか判断する    directory.md
4. spec を書く              testing.md
5. 実装する                 validation.md / constants.md / logging.md
6. 5ゲートを通す            implementation-guidelines.md（## 実装フロー）
```

CI と同じ5ゲート（rspec / rubocop / steep / brakeman / bundler-audit）が
すべて通って初めて合格。コマンドは [`CLAUDE.md`](../../CLAUDE.md) にまとめている。

## 関連ドキュメント

- [アーキテクチャ決定記録](../decisions/README.md) — なぜその作法になったか
- [システム概要](../architecture/overview.md) — システム構成・データフロー
- [API 設計方針](../api/README.md) — レスポンス形式・エラーコード
- [エンドポイント一覧](../api/endpoints.md)
