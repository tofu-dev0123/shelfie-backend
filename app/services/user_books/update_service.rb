module UserBooks
  class UpdateService
    def self.call(current_user:, isbn:, content:)
      # PUT はリソース全体の置換を要求するため、部分更新を禁止する目的で必須化している。
      # 空値にしたい場合は "" を明示的に送信する必要がある。
      raise BadRequestError if content.nil?

      tag_names = HashtagParser.extract(content)
      validate_params!(content, tag_names)

      book = Book.find_by(isbn: isbn)
      raise RecordNotFoundError unless book

      user_book = UserBook.find_by(user: current_user, book: book)
      raise RecordNotFoundError unless user_book

      ActiveRecord::Base.transaction do
        user_book.update!(content: content)

        tag_records = tag_names.map { |name| Tag.find_or_create_safely!(name) }
        user_book.tags = tag_records
      end

      Rails.logger.info "UserBooks::UpdateService: user_id=#{current_user.id} isbn=#{isbn} 本棚投稿を更新しました"
    end

    def self.validate_params!(content, tag_names)
      raise ValidationError, I18n.t("user_books.errors.content_too_long", count: UserBookConstants::MAX_CONTENT_LENGTH) if content.length > UserBookConstants::MAX_CONTENT_LENGTH
      raise ValidationError, I18n.t("user_books.errors.tags_too_many", count: UserBookConstants::MAX_TAGS) if tag_names.length > UserBookConstants::MAX_TAGS
    end
    private_class_method :validate_params!
  end
end
