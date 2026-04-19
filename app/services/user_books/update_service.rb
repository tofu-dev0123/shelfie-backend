module UserBooks
  class UpdateService
    def self.call(current_user:, isbn:, content:, purchase_links:)
      raise BadRequestError if content.nil? || purchase_links.nil?

      tag_names = HashtagParser.extract(content)
      validate_params!(content, tag_names, purchase_links)

      book = Book.find_by(isbn: isbn)
      raise RecordNotFoundError unless book

      user_book = UserBook.find_by(user: current_user, book: book)
      raise RecordNotFoundError unless user_book

      ActiveRecord::Base.transaction do
        user_book.update!(content: content)

        tag_records = tag_names.map { |name| find_or_create_tag!(name) }
        user_book.tags = tag_records

        user_book.user_book_purchase_links.destroy_all
        purchase_links.each do |url|
          UserBookPurchaseLink.create!(user_book: user_book, url: url)
        end
      end

      Rails.logger.info "UserBooks::UpdateService: user_id=#{current_user.id} isbn=#{isbn} 本棚投稿を更新しました"
    end

    # 並列リクエストで同名タグを新規作成しようとすると tags.name の unique index で
    # ActiveRecord::RecordNotUnique が起きるため、衝突時は作成済みレコードを再検索する。
    def self.find_or_create_tag!(name)
      Tag.find_or_create_by!(name: name)
    rescue ActiveRecord::RecordNotUnique
      Tag.find_by!(name: name)
    end
    private_class_method :find_or_create_tag!

    def self.validate_params!(content, tag_names, purchase_links)
      raise ValidationError, I18n.t("user_books.errors.content_too_long", count: UserBookConstants::MAX_CONTENT_LENGTH) if content.length > UserBookConstants::MAX_CONTENT_LENGTH
      raise ValidationError, I18n.t("user_books.errors.tags_too_many", count: UserBookConstants::MAX_TAGS) if tag_names.length > UserBookConstants::MAX_TAGS
      raise ValidationError, I18n.t("user_books.errors.purchase_links_too_many", count: UserBookConstants::MAX_PURCHASE_LINKS) if purchase_links.length > UserBookConstants::MAX_PURCHASE_LINKS

      purchase_links.each do |url|
        raise ValidationError.new(I18n.t("user_books.errors.purchase_link_url_invalid"), field: "purchase_links") unless url.match?(/\Ahttps?:\/\/.+/i)
        raise ValidationError.new(I18n.t("user_books.errors.purchase_link_url_too_long", count: UserBookConstants::MAX_PURCHASE_LINK_LENGTH), field: "purchase_links") if url.length > UserBookConstants::MAX_PURCHASE_LINK_LENGTH
      end
    end
    private_class_method :validate_params!
  end
end
