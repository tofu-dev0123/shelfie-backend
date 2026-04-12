class RakutenBooksClient
  BASE_URL = "https://app.rakuten.co.jp/services/api/BooksBook/Search/20170404"
  HITS     = 20
  GENRE_ID = "001020"  # コンピュータ・テクノロジー

  def self.call(q:, page: 1)
    uri = URI(BASE_URL)
    params = {
      applicationId: ENV.fetch("RAKUTEN_APP_ID", nil),
      keyword:       q,
      booksGenreId:  GENRE_ID,
      hits:          HITS,
      page:          page,
      formatVersion: 2
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    raise ExternalApiError, "Rakuten Books API error: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body, symbolize_names: true)
  rescue ExternalApiError
    raise
  rescue StandardError => e
    Rails.logger.error "Rakuten Books API 呼び出し失敗: #{e.message}"
    raise ExternalApiError, e.message
  end
end
