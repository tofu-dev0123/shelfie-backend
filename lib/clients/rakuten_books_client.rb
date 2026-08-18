class RakutenBooksClient
  BASE_URL = "https://openapi.rakuten.co.jp/services/api/BooksBook/Search/20170404"
  HITS = 20

  def self.call(q:, page: 1)
    fetch(title: q, hits: HITS, page: page)
  end

  def self.find_by_isbn(isbn:)
    fetch(isbn: isbn)
  end

  def self.fetch(query_params)
    uri = URI(BASE_URL)
    params = {
      applicationId: ENV.fetch("RAKUTEN_APP_ID", nil),
      accessKey:     ENV.fetch("RAKUTEN_ACCESS_KEY", nil),
      formatVersion: 2
    }.merge(query_params)
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri)
      request["Origin"]  = ENV.fetch("RAKUTEN_ORIGIN", "https://dev-api.shelfie.jp")
      request["Referer"] = ENV.fetch("RAKUTEN_ORIGIN", "https://dev-api.shelfie.jp")
      http.request(request)
    end
    raise ExternalApiError, "Rakuten Books API error: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body, symbolize_names: true)
  rescue ExternalApiError
    raise
  rescue StandardError => e
    Rails.logger.error "Rakuten Books API 呼び出し失敗: #{e.message}"
    raise ExternalApiError, e.message
  end
  private_class_method :fetch
end
