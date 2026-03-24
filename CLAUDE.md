# CLAUDE.md

Ruby on Rails (API mode) + PostgreSQL の JSON API サーバー。

## コマンド

```bash
docker compose exec -e RAILS_ENV=test web bundle exec rspec  # テスト
docker compose exec web bundle exec rubocop                   # Lint
docker compose exec web bundle exec steep check               # 型チェック
docker compose exec web bin/brakeman --no-pager               # セキュリティ
```

実装ガイドライン → `docs/development/implementation-guidelines.md`
