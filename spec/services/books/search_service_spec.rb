require "rails_helper"

RSpec.describe Books::SearchService do
  let(:google_books_response) do
    {
      totalItems: 100,
      items: Array.new(10) do |i|
        {
          id: "id#{i}",
          volumeInfo: {
            title: "本#{i}",
            authors: [ "著者#{i}" ],
            imageLinks: { thumbnail: "https://example.com/#{i}.jpg" }
          }
        }
      end
    }
  end

  before do
    stub_request(:get, /googleapis.com\/books\/v1\/volumes/)
      .to_return(status: 200, body: google_books_response.to_json, headers: { "Content-Type" => "application/json" })
  end

  describe ".call" do
    context "正常系" do
      it "検索結果を返す" do
        result = described_class.call(q: "Rails")

        expect(result[:items].size).to eq(10)
        expect(result[:items].first).to include(
          google_books_id: "id0",
          title: "本0",
          authors: [ "著者0" ],
          thumbnail_url: "https://example.com/0.jpg"
        )
      end

      it "取得件数が10件のとき has_next: true" do
        result = described_class.call(q: "Rails")
        expect(result[:pagination][:has_next]).to eq(true)
        expect(result[:pagination][:next_cursor]).not_to be_nil
      end

      it "取得件数が10件未満のとき has_next: false" do
        stub_request(:get, /googleapis.com\/books\/v1\/volumes/)
          .to_return(
            status: 200,
            body: { totalItems: 3, items: google_books_response[:items].first(3) }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = described_class.call(q: "Rails")
        expect(result[:pagination][:has_next]).to eq(false)
        expect(result[:pagination][:next_cursor]).to be_nil
      end

      it "検索結果 0件のとき items: [] で has_next: false" do
        stub_request(:get, /googleapis.com\/books\/v1\/volumes/)
          .to_return(status: 200, body: { totalItems: 0 }.to_json, headers: { "Content-Type" => "application/json" })

        result = described_class.call(q: "存在しない書籍")
        expect(result[:items]).to eq([])
        expect(result[:pagination][:has_next]).to eq(false)
      end

      it "cursor を渡すと次ページを取得する" do
        cursor = Base64.strict_encode64({ startIndex: 10 }.to_json)
        described_class.call(q: "Rails", cursor: cursor)

        expect(WebMock).to have_requested(:get, /googleapis.com/).with(query: hash_including("startIndex" => "10"))
      end

      it "著者不明の書籍は authors: []" do
        stub_request(:get, /googleapis.com\/books\/v1\/volumes/)
          .to_return(
            status: 200,
            body: { totalItems: 1, items: [ { id: "x", volumeInfo: { title: "無名の本" } } ] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = described_class.call(q: "Rails")
        expect(result[:items].first[:authors]).to eq([])
      end

      it "サムネイルなしの書籍は thumbnail_url: nil" do
        stub_request(:get, /googleapis.com\/books\/v1\/volumes/)
          .to_return(
            status: 200,
            body: { totalItems: 1, items: [ { id: "x", volumeInfo: { title: "サムネなし本", authors: [ "著者" ] } } ] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = described_class.call(q: "Rails")
        expect(result[:items].first[:thumbnail_url]).to be_nil
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

      it "startIndex が整数でないとき ValidationError を raise する" do
        cursor = Base64.strict_encode64({ startIndex: "ten" }.to_json)
        expect { described_class.call(q: "Rails", cursor: cursor) }.to raise_error(ValidationError)
      end
    end

    context "異常系: 外部API エラー" do
      it "Google Books API がエラーを返したとき ExternalApiError を raise する" do
        stub_request(:get, /googleapis.com\/books\/v1\/volumes/)
          .to_return(status: 500)

        expect { described_class.call(q: "Rails") }.to raise_error(ExternalApiError)
      end
    end
  end
end
