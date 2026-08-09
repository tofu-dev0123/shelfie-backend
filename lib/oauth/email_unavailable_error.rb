module Oauth
  # GitHub はメールアドレスを非公開に設定できるため、verified な primary メールが
  # 取得できないことがある。アカウントの連絡先メールが確定しないので続行できない。
  class EmailUnavailableError < StandardError; end
end
