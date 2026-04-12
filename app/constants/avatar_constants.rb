module AvatarConstants
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_FILE_SIZE         = 5.megabytes
  S3_KEY_PREFIX         = "avatars".freeze
end
