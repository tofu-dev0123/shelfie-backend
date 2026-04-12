class S3Client
  BUCKET = ENV.fetch("S3_BUCKET_NAME", nil)
  REGION = ENV.fetch("AWS_REGION", "ap-northeast-1")

  def self.delete(key:)
    client.delete_object(bucket: BUCKET, key: key)
  rescue Aws::S3::Errors::ServiceError => e
    raise S3DeleteError, e.message
  end

  def self.upload(file:, key:)
    client.put_object(
      bucket: BUCKET,
      key: key,
      body: file,
      content_type: file.content_type
    )
    key
  rescue Aws::S3::Errors::ServiceError => e
    raise S3UploadError, e.message
  end

  def self.client
    @client ||= Aws::S3::Client.new(region: REGION)
  end
  private_class_method :client
end
