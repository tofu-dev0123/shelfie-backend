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

      tag_records = Tag.where(name: tags).to_a
      raise ValidationError, Messages::UserBooks::INVALID_TAG_INCLUDED if tags.any? && tag_records.length != tags.length

      ActiveRecord::Base.transaction do
        user_book.update!(content: content)

        user_book.tags = tag_records

        user_book.user_book_purchase_links.destroy_all
        purchase_links.each do |url|
          UserBookPurchaseLink.create!(user_book: user_book, url: url)
        end
      end

      Rails.logger.info "UserBooks::UpdateService: user_id=#{current_user.id} isbn=#{isbn} 本棚投稿を更新しました"
    end

    def self.validate_params!(content, tags, purchase_links)
      raise ValidationError, Messages::UserBooks::CONTENT_TOO_LONG if content.length > UserBookConstants::MAX_CONTENT_LENGTH
      raise ValidationError, Messages::UserBooks::TAGS_TOO_MANY if tags.length > UserBookConstants::MAX_TAGS
      raise ValidationError, Messages::UserBooks::PURCHASE_LINKS_TOO_MANY if purchase_links.length > UserBookConstants::MAX_PURCHASE_LINKS

      purchase_links.each do |url|
        raise ValidationError.new(Messages::UserBooks::PURCHASE_LINK_URL_INVALID, field: "purchase_links") unless url.match?(/\Ahttps?:\/\/.+/i)
        raise ValidationError.new(Messages::UserBooks::PURCHASE_LINK_URL_TOO_LONG, field: "purchase_links") if url.length > UserBookConstants::MAX_PURCHASE_LINK_LENGTH
      end
    end
    private_class_method :validate_params!
  end
end
