module Messages
  module UserBooks
    ISBN_INVALID               = "ISBNは13桁の数字で入力してください"
    CONTENT_TOO_LONG           = "contentは#{UserBookConstants::MAX_CONTENT_LENGTH}文字以内で入力してください"
    TAGS_TOO_MANY              = "タグは最大#{UserBookConstants::MAX_TAGS}件まで設定できます"
    PURCHASE_LINKS_TOO_MANY    = "purchase_linksは最大#{UserBookConstants::MAX_PURCHASE_LINKS}件まで設定できます"
    PURCHASE_LINK_URL_INVALID  = "URLの形式が正しくありません"
    PURCHASE_LINK_URL_TOO_LONG = "URLは#{UserBookConstants::MAX_PURCHASE_LINK_LENGTH}文字以内で入力してください"
    INVALID_TAG_INCLUDED       = "存在しないタグが含まれています"
  end
end
