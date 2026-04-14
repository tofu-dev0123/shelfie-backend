module Tags
  class ListService
    def self.call
      tags = Tag.ordered.to_a
      Rails.logger.info "Tags::ListService: タグ一覧を取得しました count=#{tags.size}"
      tags
    end
  end
end
