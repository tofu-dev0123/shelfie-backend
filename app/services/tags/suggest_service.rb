module Tags
  class SuggestService
    def self.call(q:)
      validate_query!(q)

      escaped        = Tag.sanitize_sql_like(q)
      like_pattern   = "%#{escaped}%"
      prefix_pattern = "#{escaped}%"

      # 前方一致するタグを先頭に寄せ、残りは名前昇順で並べる。
      order_sql = Tag.sanitize_sql_array([ "(name ILIKE ?) DESC, name ASC", prefix_pattern ])

      tags = Tag
        .where("name ILIKE ?", like_pattern)
        .order(Arel.sql(order_sql))
        .limit(TagConstants::SUGGEST_LIMIT)
        .to_a

      Rails.logger.info "Tags::SuggestService: q=#{q} count=#{tags.size} タグ候補を取得しました"
      tags
    end

    def self.validate_query!(q)
      raise ValidationError, I18n.t("tags.errors.query_required") if q.blank?
      raise ValidationError, I18n.t("tags.errors.query_too_long", count: TagConstants::MAX_QUERY_LENGTH) if q.length > TagConstants::MAX_QUERY_LENGTH
    end
    private_class_method :validate_query!
  end
end
