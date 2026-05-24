# CloudFront を使った CDN 配信の設定定数
module CdnConstants
  CLOUDFRONT_HOST = ENV.fetch("CLOUDFRONT_HOST", nil)
  CDN_SCHEME = ENV.fetch("CDN_SCHEME", "https")

  def self.url_for(key)
    "#{CDN_SCHEME}://#{CLOUDFRONT_HOST}/#{key}"
  end
end
