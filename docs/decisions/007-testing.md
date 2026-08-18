# 007: テスト方針

## 決定日

2026-03-06

## ステータス

決定済み

## 決定内容

### テスト対象レイヤー

3レイヤー全てにテストを書く。

| レイヤー | 種類 | 置き場 |
|---|---|---|
| Model | バリデーションルールの全パターン | `spec/models/` |
| Service | 正常系・異常系のビジネスロジック | `spec/services/` |
| Request | エンドポイントのステータスコード・レスポンス形式 | `spec/requests/` |

### テスト用DBはPostgreSQLを使用する

インメモリDBは使わない。本番と同じPostgreSQLを使うことで、本番環境との挙動の差異を防ぐ。

ローカルのPostgreSQLサーバー上に `shelfie_test` DBを作成し、rspec実行時に自動接続される。テストケースごとにトランザクションをロールバックしてデータをリセットする（`use_transactional_fixtures = true`）。

### 外部APIはモックする

Clerkと楽天書籍APIは実際に叩かない。テストの安定性を保つためにスタブで偽レスポンスを返す。

| 外部API | モック方法 |
|---|---|
| Clerk | `allow(ClerkClient).to receive(:verify).and_return(...)` |
| 楽天書籍API | `stub_request` でHTTPレベルでモック |

### テストデータはFactoryBotで管理する

テストデータのひな形を `spec/factories/` に定義する。DBに保存する場合は `create`、保存しない場合は `build` を使い分ける。
