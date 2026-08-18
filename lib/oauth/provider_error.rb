module Oauth
  # プロバイダとのやり取りが信頼できないときに投げる。
  # トークン交換の失敗と id_token のクレーム不正を1つに束ねているのは、
  # 利用者（ブラウザ）に返せる情報がどちらも「プロバイダ側で失敗した」だけで同じため。
  class ProviderError < StandardError; end
end
