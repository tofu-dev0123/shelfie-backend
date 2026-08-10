# user_identities

## 概要

ユーザーと外部プロバイダ（Google / GitHub）の連携を管理するテーブル。
OAuth のコールバックで受け取った `(provider, provider_uid)` からユーザーを特定する。

**`users` にカラムを足さずテーブルを切り出しているのは、「同じ人が2つの認証手段を持てる」
ことを表現するため。** `users.provider` / `users.provider_uid` にすると
1ユーザー = 1プロバイダが構造的に固定される。

このスキーマは launch 前にしか入れられない。稼働後の移行はデータ移行を伴う。
UI（連携追加・連携解除）は後から足せるが、スキーマは後からが高い。

## カラム定義

| カラム名 | 型 | NULL | 制約 | 説明 |
|---|---|---|---|---|
| id | bigint | NO | PK | |
| user_id | bigint | NO | FK (users.id) | 連携先のユーザー |
| provider | string(20) | NO | | プロバイダ名（`google` / `github`）|
| provider_uid | string(255) | NO | | プロバイダ側のユーザー ID。Google の `sub` は最大255文字。GitHub の `id` は整数で返るため文字列化して保存する |
| email | string(254) | NO | | **そのプロバイダが返したメール**（表示・監査用）|
| created_at | datetime | NO | | |
| updated_at | datetime | NO | | |

## インデックス

| インデックス | カラム | 意図 |
|---|---|---|
| PRIMARY KEY | id | |
| UNIQUE | (provider, provider_uid) | **同じ外部 ID が2ユーザーに紐づかないことを保証する。** これが無いと、同じ Google アカウントで別ユーザーを作れてしまい、ログイン時にどちらのユーザーか決まらない |
| UNIQUE | (user_id, provider) | **同一プロバイダの二重連携を防ぐ。** 1ユーザーが Google を2つ連携できると、どちらのメールが正なのか決まらず、連携解除の対象も曖昧になる |
| INDEX | user_id | ユーザーの連携一覧取得（FK の付随インデックス）|

**この2本は役割が違う。** 前者は「外部 ID → ユーザー」の一意性（ログインの正しさ）、
後者は「ユーザー → プロバイダ」の一意性（連携管理の正しさ）を保証する。
片方だけでは他方を代替できない。

## リレーション

| 関連テーブル | 種別 | 説明 |
|---|---|---|
| users | N:1 | 連携先のユーザー。ON DELETE RESTRICT |

## email の役割

| | 意味 |
|---|---|
| `users.email` | **アカウントの連絡先メール。** サインアップ時に最初のプロバイダから設定する。UNIQUE を維持 |
| `user_identities.email` | **そのプロバイダが返したメール。** `users.email` と一致しなくてよい |

Google と GitHub で別のメールを使っている場合、`user_identities.email` は
プロバイダごとに異なる値になる。**このカラムに UNIQUE を付けない**のはそのため。

## 備考

- **v1 では 1ユーザー = 1 identity。** 複数プロバイダの明示的な連携（`intent=link`）は
  v2 のスコープで、スキーマ変更もデータ移行も不要で足せる
- 同一メールで別プロバイダが来たときは自動紐付けしない（P1）。理由 → [サインアップフロー](../signup.md#同一メールで別プロバイダが来たときのポリシーp1拒否して案内)

## 関連ドキュメント

- [認証フロー](../auth.md)
- [サインアップフロー](../signup.md)
- [users テーブル定義](./users.md)
