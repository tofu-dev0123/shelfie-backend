# CloudFront を使った CDN 配信の設定定数
module CdnConstants
  CLOUDFRONT_HOST = ENV.fetch("CLOUDFRONT_HOST", nil)
end
