module Oauth
  module Providers
    # 許可プロバイダの正は user_identities の許可リスト。ここで再掲すると、
    # 片方だけ増えたときに「モデルは通るがレジストリで弾かれる」が起きる。
    NAMES = UserIdentityConstants::PROVIDERS

    # Zeitwerk のリロードでクラスオブジェクトを掴んだままにしないよう、名前で解決する。
    def self.fetch(name)
      name = name.to_s
      raise UnsupportedProviderError, name unless NAMES.include?(name)

      "Oauth::Providers::#{name.camelize}".constantize
    end
  end
end
