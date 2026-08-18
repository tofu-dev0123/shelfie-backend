module Oauth
  # レジストリに登録されていないプロバイダ名を渡されたときに投げる。
  class UnsupportedProviderError < StandardError; end
end
