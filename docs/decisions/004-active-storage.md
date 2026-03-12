# 004: ファイルストレージの方針

## 決定日

2026-03-12（2026-03-06 の決定を更新）

## ステータス

決定済み

## 背景

ユーザーのアバター画像をS3に保存する必要があった。S3との連携をどのように実装するか、またプロフィール更新APIとの関係を決定する必要があった。

当初はActiveStorageを採用する方針だったが、今回の用途（プロフィール画像1枚のみ）に対してオーバースペックであると判断し、`aws-sdk-s3` を直接使用する方針に変更した。

## 決定内容

### S3連携: aws-sdk-s3 を直接使用する

ActiveStorageは使用せず、`aws-sdk-s3` gem を直接使ってS3との連携を実装する。

```ruby
# Userテーブルに avatar_key カラムを追加
# 例: "profile-images/user_123.jpg"

# アップロード
s3_client.put_object(
  bucket: ENV["S3_BUCKET"],
  key: "profile-images/user_#{user.id}.jpg",
  body: params[:avatar]
)
user.update!(avatar_key: "profile-images/user_#{user.id}.jpg")

# CloudFrontのURL生成
"https://#{ENV['CLOUDFRONT_HOST']}/#{user.avatar_key}"

# 削除
s3_client.delete_object(bucket: ENV["S3_BUCKET"], key: user.avatar_key)
user.update!(avatar_key: nil)
```

### アバター画像は専用のAPIエンドポイントで扱う

`PATCH /v1/me`（テキスト情報更新）とは別に、アバター画像専用のエンドポイントを設ける。

| メソッド | パス | 説明 |
|---|---|---|
| POST | `/v1/me/avatar` | アバター画像アップロード |
| DELETE | `/v1/me/avatar` | アバター画像削除 |

## 理由

### aws-sdk-s3 を直接使用する理由

- 管理対象はプロフィール画像1枚のみであり、ActiveStorageの恩恵（複数ファイル・複数モデル管理）を受けない
- ActiveStorageは専用テーブルが3つ（`active_storage_blobs` など）増えるが、今回の用途には不要
- ActiveStorageはデフォルトでS3のURLを生成するため、CloudFrontのURLを返すには追加実装が必要になる
- `avatar_key`（S3のキーパス）をUsersテーブルに直接持つことで、URLの組み立てがシンプルになる
- CloudFrontドメインが変わっても、DBのデータ（キーパス）はそのまま使える

### アバター専用エンドポイントにした理由

- `PATCH /v1/me` は `Content-Type: application/json` でテキスト情報を更新する
- 画像アップロードは `Content-Type: multipart/form-data` が必要
- 同一エンドポイントで異なるContent-Typeを扱うと、フロントエンド・バックエンド両方の実装が複雑になる
- 分離することで各エンドポイントの責務が明確になる

## 変更履歴

| 日付 | 内容 |
|---|---|
| 2026-03-06 | ActiveStorageを採用する方針で決定 |
| 2026-03-12 | aws-sdk-s3 直接使用に変更。理由：今回の用途に対してActiveStorageはオーバースペック |
