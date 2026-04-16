require "rails_helper"

RSpec.describe WantToReads::CreateService, type: :service do
  let(:user) { create(:user) }
  let(:isbn) { "9784873116068" }
  let(:book_item) do
    {
      isbn:          isbn,
      title:         "リーダブルコード",
      author:        "Dustin Boswell／Trevor Foucher",
      largeImageUrl: "https://thumbnail.image.rakuten.co.jp/test.jpg"
    }
  end
  let(:rakuten_response) { { Items: [ book_item ], count: 1 } }

  describe ".call" do
    context "正常系" do
      context "DBに書籍が既に存在する場合" do
        let!(:book) { create(:book, isbn: isbn) }

        it "WantToRead レコードが作成される" do
          expect { described_class.call(current_user: user, isbn: isbn) }
            .to change(WantToRead, :count).by(1)
        end

        it "楽天APIを呼ばない" do
          expect(RakutenBooksClient).not_to receive(:find_by_isbn)
          described_class.call(current_user: user, isbn: isbn)
        end
      end

      context "DBに書籍が存在しない場合" do
        before do
          stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
            .to_return(status: 200, body: rakuten_response.to_json, headers: { "Content-Type" => "application/json" })
        end

        it "Book レコードが作成される" do
          expect { described_class.call(current_user: user, isbn: isbn) }
            .to change(Book, :count).by(1)
        end

        it "WantToRead レコードが作成される" do
          expect { described_class.call(current_user: user, isbn: isbn) }
            .to change(WantToRead, :count).by(1)
        end
      end
    end

    context "異常系" do
      it "isbn が13桁の数字でないとき ValidationError を raise する" do
        expect { described_class.call(current_user: user, isbn: "invalid") }
          .to raise_error(ValidationError)
      end

      it "楽天APIに書籍が存在しないとき RecordNotFoundError を raise する" do
        stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
          .to_return(status: 200, body: { Items: [], count: 0 }.to_json, headers: { "Content-Type" => "application/json" })

        expect { described_class.call(current_user: user, isbn: isbn) }
          .to raise_error(RecordNotFoundError)
      end

      it "既に読みたいリストに追加済みのとき WantToReadAlreadyExistsError を raise する" do
        book = create(:book, isbn: isbn)
        create(:want_to_read, user: user, book: book)

        expect { described_class.call(current_user: user, isbn: isbn) }
          .to raise_error(WantToReadAlreadyExistsError)
      end

      it "楽天APIがエラーのとき ExternalApiError を raise する" do
        stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
          .to_return(status: 500)

        expect { described_class.call(current_user: user, isbn: isbn) }
          .to raise_error(ExternalApiError)
      end
    end
  end
end
