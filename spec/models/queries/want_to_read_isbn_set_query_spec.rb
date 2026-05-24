require "rails_helper"

RSpec.describe Queries::WantToReadIsbnSetQuery do
  describe ".call" do
    let(:user) { create(:user) }
    let(:book_a) { create(:book, isbn: "9784000000001") }
    let(:book_b) { create(:book, isbn: "9784000000002") }
    let(:book_c) { create(:book, isbn: "9784000000003") }

    context "user が nil の場合" do
      it "nil を返す（未ログインを示す）" do
        expect(described_class.call(user: nil, isbns: [ "9784000000001" ])).to be_nil
      end
    end

    context "isbns が空配列の場合" do
      it "空の Set を返す" do
        result = described_class.call(user: user, isbns: [])
        expect(result).to eq(Set.new)
      end
    end

    context "isbns に登録済みと未登録が混在する場合" do
      before do
        create(:want_to_read, user: user, book: book_a)
        create(:want_to_read, user: user, book: book_c)
      end

      it "登録済み ISBN のみの Set を返す" do
        result = described_class.call(user: user, isbns: [ book_a.isbn, book_b.isbn, book_c.isbn ])
        expect(result).to eq(Set.new([ book_a.isbn, book_c.isbn ]))
      end
    end

    context "別ユーザーの読みたいリストは含めない" do
      let(:other_user) { create(:user) }

      before do
        create(:want_to_read, user: other_user, book: book_a)
      end

      it "他人の追加分は無視され空 Set を返す" do
        result = described_class.call(user: user, isbns: [ book_a.isbn ])
        expect(result).to eq(Set.new)
      end
    end

    context "isbns に DB 未登録の ISBN が含まれる場合" do
      it "存在しない ISBN は単に Set に含まれないだけ" do
        result = described_class.call(user: user, isbns: [ "9999999999999" ])
        expect(result).to eq(Set.new)
      end
    end
  end
end
