namespace :dev do
  desc "開発用 JWT を発行する。Usage: rake dev:clerk_jwt CLERK_USER_ID=user_xxx EMAIL=test@example.com"
  task clerk_jwt: :environment do
    abort "このタスクは development 環境専用です" unless Rails.env.development?

    dev_secret = ENV["DEV_JWT_SECRET"] or abort "DEV_JWT_SECRET が設定されていません（.env.local に追加してください）"
    clerk_user_id = ENV["CLERK_USER_ID"] or abort "CLERK_USER_ID を指定してください。例: rake dev:clerk_jwt CLERK_USER_ID=user_xxx EMAIL=test@example.com"
    email = ENV["EMAIL"] or abort "EMAIL を指定してください。例: rake dev:clerk_jwt CLERK_USER_ID=user_xxx EMAIL=test@example.com"

    payload = { sub: clerk_user_id, email: email, exp: 1.hour.from_now.to_i }
    jwt = JWT.encode(payload, dev_secret, "HS256")

    puts "\n--- 開発用 JWT ---"
    puts jwt
    puts "------------------"
    puts "\ncurl 例:"
    puts %(curl -X POST http://localhost:3000/v1/users \\)
    puts %(  -H "Content-Type: application/json" \\)
    puts %(  -H "Authorization: Bearer #{jwt}" \\)
    puts %(  -d '{"nickname": "テスト", "username": "testuser"}')
  end
end
