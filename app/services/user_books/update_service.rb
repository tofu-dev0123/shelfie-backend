module UserBooks
  class UpdateService
    def self.call(current_user:, isbn:, content:, tags:, purchase_links:)
      raise BadRequestError if content.nil? || tags.nil? || purchase_links.nil?

      tags           = tags.uniq
      validate_params!(content, tags, purchase_links)

      book = Book.find_by(isbn: isbn)
      raise RecordNotFoundError unless book

      user_book = UserBook.find_by(user: current_user, book: book)
      raise RecordNotFoundError unless user_book

      ActiveRecord::Base.transaction do
        user_book.update!(content: content)

        user_book.user_book_tags.destroy_all
        if tags.any?
          tag_records = Tag.where(name: tags)
          raise ValidationError, "存在しないタグが含まれています" if tag_records.count != tags.uniq.length

          tag_records.each { |tag| UserBookTag.create!(user_book: user_book, tag: tag) }
        end

        user_book.user_book_purchase_links.destroy_all
        purchase_links.each do |url|
          UserBookPurchaseLink.create!(user_book: user_book, url: url)
        end
      end

      Rails.logger.info "UserBooks::UpdateService: user_id=#{current_user.id} isbn=#{isbn} 本棚投稿を更新しました"
    end

    def self.validate_params!(content, tags, purchase_links)
      raise ValidationError, "contentは#{UserBookConstants::MAX_CONTENT_LENGTH}文字以内で入力してください" if content.length > UserBookConstants::MAX_CONTENT_LENGTH
      raise ValidationError, "タグは最大#{UserBookConstants::MAX_TAGS}件まで設定できます" if tags.length > UserBookConstants::MAX_TAGS
      raise ValidationError, "purchase_linksは最大#{UserBookConstants::MAX_PURCHASE_LINKS}件まで設定できます" if purchase_links.length > UserBookConstants::MAX_PURCHASE_LINKS

      purchase_links.each do |url|
        raise ValidationError.new("URLの形式が正しくありません", field: "purchase_links") unless url.match?(/\Ahttps?:\/\/.+/i)
        raise ValidationError.new("URLは#{UserBookConstants::MAX_PURCHASE_LINK_LENGTH}文字以内で入力してください", field: "purchase_links") if url.length > UserBookConstants::MAX_PURCHASE_LINK_LENGTH
      end
    end
    private_class_method :validate_params!
  end
end
