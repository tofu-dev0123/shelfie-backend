# ストレージ構成

## 概要

プロフィール画像の保存・配信に AWS S3 + CloudFront を使用する。

---

## 構成図

```
【アップロード】
クライアント
  │ POST /v1/me/avatar（multipart/form-data）
  ▼
Rails（aws-sdk-s3）
  │ S3 に put_object
  ▼
S3（非公開バケット）

【配信】
クライアント
  │ GET /v1/users/:username など
  ▼
Rails
  │ CloudFront の URL を JSON レスポンスで返す
  ▼
クライアント
  │ CloudFront URL に直接リクエスト
  ▼
CloudFront → S3（キャッシュがあれば S3 は叩かない）
```

---

## S3 バケット構成

| 環境 | バケット名 |
|---|---|
| 本番 | `shelfie-profile-images-prod` |
| ステージング | `shelfie-profile-images-staging` |

- 環境ごとにバケットを分けることで、本番データへの誤操作リスクを防ぐ
- パブリックアクセスは**完全ブロック**
- CloudFront 経由のアクセスのみ許可（OAC を使用）

---

## CloudFront 構成

| 項目 | 設定 |
|---|---|
| ドメイン | デフォルトの CloudFront ドメイン（`*.cloudfront.net`） |
| オリジン | S3 バケット |
| オリジンアクセス | OAC（Origin Access Control） |
| 署名付きURL | 使用しない（プロフィール画像は公開情報） |

---

## データ管理

S3 のキーパスを Users テーブルの `avatar_key` カラムに保存する。

```
# avatar_key の例
"profile-images/user_123.jpg"
```

CloudFront の URL はレスポンス時に動的に組み立てる。DBにはURLそのものを保存しない。

```ruby
# URL組み立て例
"https://#{ENV['CLOUDFRONT_HOST']}/#{user.avatar_key}"
```

**DBにURLではなくキーパスを保存する理由:**
CloudFront ドメインが将来変わった場合でも、DB のデータをマイグレーションせずに対応できる。

---

## 使用 gem

| gem | 用途 |
|---|---|
| `aws-sdk-s3` | S3 へのアップロード・削除 |

---

## 環境変数

| 変数名 | 説明 |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS アクセスキー |
| `AWS_SECRET_ACCESS_KEY` | AWS シークレットキー |
| `AWS_REGION` | リージョン（例: `ap-northeast-1`） |
| `S3_BUCKET` | S3 バケット名 |
| `CLOUDFRONT_HOST` | CloudFront ドメイン（例: `d1234abcd.cloudfront.net`） |

---

## 関連ドキュメント

- [ファイルストレージの方針](../decisions/004-active-storage.md)
- [アバター画像アップロード API](../api/users/avatar_upload.md)
- [アバター画像削除 API](../api/users/avatar_destroy.md)
