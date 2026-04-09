module Users
  class CheckUsernameService
    def self.call(value:)
      raise BadRequestError, "value is required" if value.blank?

      available = !User.exists?(username: value)
      { available: available }
    end
  end
end
