module HashtagParser
  # content 中の `#xxx` を抽出しタグ名の配列を返す。
  # DB・外部API に依存しない純粋関数のため lib/ 直下に配置する。
  module_function

  def extract(content)
    return [] if content.blank?

    content.scan(UserBookConstants::HASHTAG_REGEX).flatten.uniq
  end
end
