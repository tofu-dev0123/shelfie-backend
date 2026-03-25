# PATCH /v1/me

## 概要

ログイン中のユーザー自身のプロフィールを更新する。

## リクエスト

### 認証

`Authorization: Bearer <アクセストークン>`

### ボディ

送信したフィールドのみ更新する。全フィールド未送信または全フィールドが空の場合はバリデーションエラー。

```json
{
  "nickname": "コムさん",
  "bio": "エンジニアです",
  "links": ["https://github.com/komusan", "https://x.com/komusan"]
}
```

| フィールド | 型 | 必須 | バリデーション |
|---|---|---|---|
| `nickname` | string | 任意 | 最大50文字 |
| `bio` | string | 任意 | 最大200文字 |
| `links` | array | 任意 | 最大5件、各要素はURL形式 |

### `links` の挙動

| 送信内容 | 挙動 |
|---|---|
| フィールド自体を省略 | リンクは変更しない |
| `links: []` | 全件削除 |
| `links: [...]` | 全件置き換え |

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. 送信されたフィールドのみバリデーション
3. トランザクション内で以下を実行
   - `nickname` / `bio` が含まれる場合、User レコードを更新
   - `links` が含まれる場合、`user_links` レコードを全削除して新規作成
4. 更新後のプロフィール情報を返す

## レスポンス

### 成功

```json
// 200 OK
{
  "nickname": "コムさん",
  "bio": "エンジニアです",
  "links": ["https://github.com/komusan", "https://x.com/komusan"]
}
```

- `nickname` / `bio` / `links` は常に全て返す（links が空の場合は空配列 `[]`）

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | アクセストークンが無効・期限切れ |
| `BAD_REQUEST` | 400 | 全フィールド未送信 |
| `UNPROCESSABLE_ENTITY` | 422 | バリデーション違反 |

#### バリデーションエラーのレスポンス例

```json
// 422 Unprocessable Entity
{
  "error": {
    "code": "UNPROCESSABLE_ENTITY",
    "message": "入力内容に誤りがあります",
    "details": [
      { "field": "nickname", "message": "ニックネームは50文字以内で入力してください" },
      { "field": "bio", "message": "自己紹介は200文字以内で入力してください" },
      { "field": "links", "message": "リンクは5件以内で入力してください" },
      { "field": "links[1]", "message": "正しいURL形式で入力してください" }
    ]
  }
}
```
