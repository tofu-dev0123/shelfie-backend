module Queries
  # 指定ユーザーが「読みたい」に追加している書籍のうち、引数 isbns に含まれるものの ISBN を Set で返す。
  # Serializer 側で「リスト要素が読みたい登録済みか」を1クエリで判定するために利用する。
  class WantToReadIsbnSetQuery
    # user が nil（未ログイン）の場合は判定不能を表す nil を返す。
    # 呼び出し側はこの戻り値を Serializer に渡し、Serializer は nil → is_in_my_want_to_read: nil として扱う。
    def self.call(user:, isbns:)
      return nil unless user
      return Set.new if isbns.blank?

      WantToRead
        .joins(:book)
        .where(user_id: user.id, books: { isbn: isbns })
        .pluck("books.isbn")
        .to_set
    end
  end
end
