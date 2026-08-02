module UserBookConstants
  MAX_LIMIT                = 50
  DEFAULT_LIMIT            = 20
  MAX_CONTENT_LENGTH       = 1000
  MAX_TAGS                 = 5

  # content 中に埋め込まれたハッシュタグ `#xxx` を抽出する正規表現。
  # 許容文字: Unicode の文字（\p{L}）・数字（\p{N}）・アンダースコア。
  # 長さ上限は tags.name の DB 制約（50文字）に合わせる。
  HASHTAG_REGEX = /#([\p{L}\p{N}_]{1,50})/
end
