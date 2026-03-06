# 004: ファイルストレージの方針

## 決定日

2026-03-06

## ステータス

決定済み

## 背景

ユーザーのアバター画像をS3に保存する必要があった。S3との連携をどのように実装するか、またプロフィール更新APIとの関係を決定する必要があった。

## 決定内容

### S3連携: ActiveStorageを使用する

gem（`aws-sdk-s3`）を直接ラップした独自クライアントは作成せず、Rails標準のActiveStorageを使用する。

```ruby
# モデル
class User < ApplicationRecord
  has_one_attached :avatar
end

# アップロード
user.avatar.attach(params[:avatar])

# URL取得
url_for(user.avatar)

# 削除
user.avatar.purge
```

### アバター画像は専用のAPIエンドポイントで扱う

`PATCH /v1/me`（テキスト情報更新）とは別に、アバター画像専用のエンドポイントを設ける。

| メソッド | パス | 説明 |
|---|---|---|
| POST | `/v1/me/avatar` | アバター画像アップロード |
| DELETE | `/v1/me/avatar` | アバター画像削除 |

## 理由

### ActiveStorageを選んだ理由

- 画像アップロードはバリデーション・URL管理など複雑な処理を伴うため、自前実装のコストが高い
- Rails公式サポートであり、情報が豊富
- S3への接続設定が `config/storage.yml` に集約でき、コードが簡潔になる

### アバター専用エンドポイントにした理由

- `PATCH /v1/me` は `Content-Type: application/json` でテキスト情報を更新する
- 画像アップロードは `Content-Type: multipart/form-data` が必要
- 同一エンドポイントで異なるContent-Typeを扱うと、フロントエンド・バックエンド両方の実装が複雑になる
- 分離することで各エンドポイントの責務が明確になる
