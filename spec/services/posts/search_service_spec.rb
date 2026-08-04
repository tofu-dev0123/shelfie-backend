require "rails_helper"

RSpec.describe Posts::SearchService, type: :service do
  describe ".call" do
    context "本文検索（q 指定）" do
      it "部分一致した投稿を返す（大文字小文字を区別しない）" do
        ub1 = create(:user_book, content: "Ruby on Rails の本でした")
        create(:user_book, content: "Go の本でした")
        ub3 = create(:user_book, content: "ruby は良い言語")

        result = described_class.call(q: "Ruby")

        ids = result[:items].map { |i| i[:id] }
        expect(ids).to contain_exactly(ub1.id, ub3.id)
      end

      it "前後の空白はトリムされる" do
        ub = create(:user_book, content: "テスト投稿")
        result = described_class.call(q: "  テスト  ")
        expect(result[:items].map { |i| i[:id] }).to eq([ ub.id ])
      end

      it "ILIKE のメタ文字（% _）をリテラルとして扱う" do
        ub = create(:user_book, content: "100%満足")
        create(:user_book, content: "1000円")

        result = described_class.call(q: "100%")

        expect(result[:items].map { |i| i[:id] }).to eq([ ub.id ])
      end
    end

    context "タグ検索（tag 指定）" do
      it "完全一致した投稿を返す" do
        go_tag    = create(:tag, name: "Go")
        golang_tag = create(:tag, name: "Golang")
        ub_go     = create(:user_book)
        ub_golang = create(:user_book)
        create(:user_book_tag, user_book: ub_go,     tag: go_tag)
        create(:user_book_tag, user_book: ub_golang, tag: golang_tag)

        result = described_class.call(tag: "Go")

        expect(result[:items].map { |i| i[:id] }).to eq([ ub_go.id ])
      end
    end

    context "ページネーション" do
      it "limit + 1 を取得して has_next を判定する" do
        create_list(:user_book, 3, content: "テスト")
        result = described_class.call(q: "テスト", limit: 1)
        expect(result[:items].size).to eq(1)
        expect(result[:pagination][:has_next]).to eq(true)
        expect(result[:pagination][:next_cursor]).not_to be_nil
      end

      it "cursor 指定で次ページを返す" do
        ubs = create_list(:user_book, 3, content: "テスト").sort_by(&:id).reverse
        cursor = CompoundCursor.encode(created_at: ubs[0].created_at, id: ubs[0].id)
        result = described_class.call(q: "テスト", cursor: cursor, limit: 10)
        expect(result[:items].map { |i| i[:id] }).to eq([ ubs[1].id, ubs[2].id ])
      end

      it "旧形式カーソル ({id} のみ) でも次ページを返す（後方互換）" do
        ubs = create_list(:user_book, 3, content: "テスト").sort_by(&:id).reverse
        legacy_cursor = Base64.strict_encode64({ id: ubs[0].id }.to_json)
        result = described_class.call(q: "テスト", cursor: legacy_cursor, limit: 10)
        expect(result[:items].map { |i| i[:id] }).to eq([ ubs[1].id, ubs[2].id ])
      end

      it "limit が 0 以下ならデフォルト値を使う" do
        create_list(:user_book, 1, content: "テスト")
        result = described_class.call(q: "テスト", limit: 0)
        expect(result[:items].size).to eq(1)
      end

      it "limit が上限を超えたらクランプされる" do
        create_list(:user_book, 1, content: "テスト")
        result = described_class.call(q: "テスト", limit: 9999)
        expect(result[:items].size).to eq(1)
      end
    end

    context "バリデーション" do
      it "q と tag のどちらも未指定の場合は ValidationError" do
        expect { described_class.call }.to raise_error(ValidationError)
      end

      it "q と tag を同時指定した場合は ValidationError" do
        expect { described_class.call(q: "a", tag: "b") }.to raise_error(ValidationError)
      end

      it "q が長すぎる場合は ValidationError" do
        expect { described_class.call(q: "a" * 101) }.to raise_error(ValidationError)
      end

      it "tag が長すぎる場合は ValidationError" do
        expect { described_class.call(tag: "a" * 51) }.to raise_error(ValidationError)
      end
    end
  end
end
