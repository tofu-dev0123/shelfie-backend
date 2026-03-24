module Users
  class CheckUsernameService
    def self.call(value:)
      raise BadRequestError, "value is required" if value.blank?

      validate_format!(value)

      available = !User.exists?(username: value)
      { available: available }
    end

    def self.validate_format!(value)
      if value.length < User::USERNAME_MIN_LENGTH || value.length > User::USERNAME_MAX_LENGTH
        raise ValidationError, "username length is invalid"
      end

      unless User::USERNAME_REGEX.match?(value)
        raise ValidationError, "username contains invalid characters"
      end

      raise ValidationError, "username cannot contain consecutive underscores" if value.include?("__")
    end
    private_class_method :validate_format!
  end
end
