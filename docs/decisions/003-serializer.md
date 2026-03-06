# 003: シリアライザーの方針

## 決定日

2026-03-06

## ステータス

決定済み

## 背景

APIレスポンスのJSON組み立てロジックをどこで管理するか、またgemを使うか素のRubyクラスで実装するかを決定する必要があった。

## 決定内容

### 実装方針

gem（Blueprinterなど）は使わず、**素のRubyクラスで実装する**。

```ruby
# app/serializers/user_serializer.rb
class UserSerializer
  def initialize(user)
    @user = user
  end

  def as_json
    {
      username: @user.username,
      nickname: @user.nickname,
      bio: @user.bio,
      links: @user.user_links.map(&:url)
    }
  end
end

# Controllerからの呼び出し
render json: UserSerializer.new(user).as_json
```

### 置き場

```
app/serializers/
├── user_serializer.rb
├── book_serializer.rb
└── user_book_serializer.rb
```

## 理由

- レスポンスの形はAPI設計で定義済みであり、シリアライザーに複雑な処理は不要
- gemの抽象化に頼らず「何をJSONに変換しているか」が明確に見える
- 挙動が完全に把握でき、学習効率が高い
- 将来的に同じパターンの繰り返しが辛くなったタイミングでgemへの移行を検討する
