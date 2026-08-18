# Shelfie Backend ドキュメント

本棚・読書記録共有サービス **Shelfie** の JSON API サーバーのドキュメント。

## 4つの区画

**どこに何を書くかが区画で決まっている。** 迷ったらこの表に戻る。

| 区画 | 何が書いてあるか | 何を書かないか |
|---|---|---|
| [architecture/](./architecture/overview.md) | システム構成・認証フロー・データモデル・テーブル定義 | 実装の作法 |
| [api/](./api/README.md) | **実装済み** API の仕様書。レスポンス形式・エラーコード | 未実装 API の仕様（新規は issue が正）|
| [development/](./development/README.md) | 実装の作法。禁止事項・レイヤーの判断基準・spec の書き方 | 設計判断の理由 |
| [decisions/](./decisions/README.md) | アーキテクチャ決定記録（ADR）。**なぜそう決めたか** | 実装の作法 |

## 目的から引く

| 知りたいこと | 行き先 |
|---|---|
| これから実装する | [実装ガイドライン](./development/implementation-guidelines.md) → [ディレクトリ構成](./development/directory.md) |
| どのレイヤーに書くか迷った | [ディレクトリ構成 / 判断基準まとめ](./development/directory.md#判断基準まとめ) |
| 既存 API の仕様を知りたい | [エンドポイント一覧](./api/endpoints.md) |
| ログイン・サインアップの流れ | [認証フロー](./architecture/auth.md) / [サインアップフロー](./architecture/signup.md) |
| テーブルのカラムと制約 | [データモデル](./architecture/data-model.md) |
| なぜこの設計なのか | [ADR 一覧](./decisions/README.md) |
| ローカル環境を立てる | [Docker 環境構築](./development/docker.md) |

## 仕様の正はどこか

- **新規作成・仕様変更のときは issue が正。** 起票の段階で仕様を確定させる
- `api/**` は**実装済み** API の仕様書であり、**実装と同じ PR で更新する**。
  「実装してからドキュメントを別 PR で直す」はしない
- `decisions/**` は**歴史的記録**。方針が変わっても当時の判断を書き換えず、
  新しい番号の ADR を起票する

## 関連

- [`CLAUDE.md`](../CLAUDE.md) — テスト・Lint・型チェックのコマンド、自動ループの運用
- [`README.md`](../README.md) — セットアップ手順
