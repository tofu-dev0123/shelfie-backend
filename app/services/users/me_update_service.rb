module Users
  class MeUpdateService
    def self.call(current_user:, attrs:)
      links = attrs.delete(:links)

      raise BadRequestError, "更新フィールドが指定されていません" if attrs.empty? && links.nil?

      ActiveRecord::Base.transaction do
        current_user.assign_attributes(attrs) if attrs.any?
        current_user.links_input = links unless links.nil?
        current_user.save!

        unless links.nil?
          current_user.user_links.delete_all
          links.each { |url| current_user.user_links.create!(url: url) }
        end
      end

      current_user.user_links.reset

      Rails.logger.info "Users::MeUpdateService: user_id=#{current_user.id} のプロフィールを更新しました"

      current_user
    end
  end
end
