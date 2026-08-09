module Oauth
  # プロバイダ差を吸収したあとの本人情報。
  # これ以降の処理は Google / GitHub のどちらから来たかを意識しない。
  Identity = Data.define(:provider, :uid, :email, :name)
end
