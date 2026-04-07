class GoogleBooksClient
  BASE_URL = "https://www.googleapis.com/books/v1/volumes"
  MAX_RESULTS = 10

  def self.call(q:, start_index: 0)
    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(
      q: q,
      startIndex: start_index,
      maxResults: MAX_RESULTS
    )

    response = Net::HTTP.get_response(uri)
    raise ExternalApiError, "Google Books API error: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body, symbolize_names: true)
  rescue ExternalApiError
    raise
  rescue StandardError => e
    Rails.logger.error "Google Books API 呼び出し失敗: #{e.message}"
    raise ExternalApiError, e.message
  end
end
