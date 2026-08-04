require "rails_helper"

RSpec.describe Books::SearchService do
  let(:rakuten_books_response) do
    {
      count: 100,
      page: 1,
      pageCount: 5,
      Items: Array.new(20) do |i|
        {
          isbn: "978000000#{i.to_s.rjust(4, '0')}",
          title: "本#{i}",
          author: "著者#{i}",
          largeImageUrl: "https://example.com/#{i}.jpg"
        }
      end
    }
  end

  before do
    stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
      .to_return(status: 200, body: rakuten_books_response.to_json, headers: { "Content-Type" => "application/json" })
  end

  describe ".call" do
    context "正常系" do
      it "検索結果を返す" do
        result = described_class.call(q: "Rails")

        expect(result[:items].size).to eq(20)
        expect(result[:items].first).to include(
          isbn: "9780000000000",
          title: "本0",
          authors: [ "著者0" ],
          thumbnail_url: "https://example.com/0.jpg"
        )
      end

      it "pageCount より page が小さいとき has_next: true" do
        result = described_class.call(q: "Rails")
        expect(result[:pagination][:has_next]).to eq(true)
        expect(result[:pagination][:next_cursor]).not_to be_nil
      end

      it "最終ページのとき has_next: false" do
        stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
          .to_return(
            status: 200,
            body: { count: 3, page: 1, pageCount: 1, Items: rakuten_books_response[:Items].first(3) }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = described_class.call(q: "Rails")
        expect(result[:pagination][:has_next]).to eq(false)
        expect(result[:pagination][:next_cursor]).to be_nil
      end

      it "検索結果 0件のとき items: [] で has_next: false" do
        stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
          .to_return(status: 200, body: { count: 0, page: 1, pageCount: 0, Items: [] }.to_json, headers: { "Content-Type" => "application/json" })

        result = described_class.call(q: "存在しない書籍")
        expect(result[:items]).to eq([])
        expect(result[:pagination][:has_next]).to eq(false)
      end

      it "cursor を渡すと次ページを取得する" do
        cursor = Base64.strict_encode64({ page: 2 }.to_json)
        described_class.call(q: "Rails", cursor: cursor)

        expect(WebMock).to have_requested(:get, /openapi\.rakuten\.co\.jp/).with(query: hash_including("page" => "2"))
      end

      it "著者不明の書籍は authors: []" do
        stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
          .to_return(
            status: 200,
            body: { count: 1, page: 1, pageCount: 1, Items: [ { isbn: "9784000000001", title: "無名の本" } ] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = described_class.call(q: "Rails")
        expect(result[:items].first[:authors]).to eq([])
      end

      it "サムネイルなしの書籍は thumbnail_url: nil" do
        stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
          .to_return(
            status: 200,
            body: { count: 1, page: 1, pageCount: 1, Items: [ { isbn: "9784000000001", title: "サムネなし本", author: "著者" } ] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = described_class.call(q: "Rails")
        expect(result[:items].first[:thumbnail_url]).to be_nil
      end

      it "複数著者は ／ で分割して配列にする" do
        stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
          .to_return(
            status: 200,
            body: { count: 1, page: 1, pageCount: 1, Items: [ { isbn: "9784000000001", title: "共著本", author: "著者A／著者B" } ] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = described_class.call(q: "Rails")
        expect(result[:items].first[:authors]).to eq([ "著者A", "著者B" ])
      end
    end

    context "異常系: q のバリデーション" do
      it "q が空のとき ValidationError を raise する" do
        expect { described_class.call(q: "") }.to raise_error(ValidationError)
      end

      it "q が空白のみのとき ValidationError を raise する" do
        expect { described_class.call(q: "   ") }.to raise_error(ValidationError)
      end

      it "q が100文字超のとき ValidationError を raise する" do
        expect { described_class.call(q: "a" * 101) }.to raise_error(ValidationError)
      end

      it "q がちょうど100文字のとき通過する" do
        expect { described_class.call(q: "a" * 100) }.not_to raise_error
      end
    end

    context "異常系: cursor のバリデーション" do
      it "不正な cursor のとき ValidationError を raise する" do
        expect { described_class.call(q: "Rails", cursor: "invalid!!!") }.to raise_error(ValidationError)
      end

      it "Base64 デコードできても JSON が不正のとき ValidationError を raise する" do
        cursor = Base64.strict_encode64("not json")
        expect { described_class.call(q: "Rails", cursor: cursor) }.to raise_error(ValidationError)
      end

      it "page が整数でないとき ValidationError を raise する" do
        cursor = Base64.strict_encode64({ page: "two" }.to_json)
        expect { described_class.call(q: "Rails", cursor: cursor) }.to raise_error(ValidationError)
      end
    end

    context "異常系: 外部API エラー" do
      it "楽天 Books API がエラーを返したとき ExternalApiError を raise する" do
        stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
          .to_return(status: 500)

        expect { described_class.call(q: "Rails") }.to raise_error(ExternalApiError)
      end
    end
  end
end
