require "rails_helper"

RSpec.describe CompoundCursor do
  describe ".encode" do
    it "created_at と id を Base64 エンコードしたカーソル文字列を返す" do
      time = Time.zone.parse("2026-05-28T12:34:56.123456Z")
      cursor = described_class.encode(created_at: time, id: 42)

      decoded = JSON.parse(Base64.strict_decode64(cursor))
      expect(decoded).to eq("created_at" => "2026-05-28T12:34:56.123456Z", "id" => 42)
    end
  end

  describe ".decode" do
    context "新形式 ({created_at, id}) のカーソルの場合" do
      it "created_at(Time) と id(Integer) を含むハッシュを返す" do
        time = Time.zone.parse("2026-05-28T12:34:56.123456Z")
        cursor = described_class.encode(created_at: time, id: 42)

        result = described_class.decode(cursor)

        expect(result[:id]).to eq(42)
        expect(result[:created_at].iso8601(6)).to eq(time.iso8601(6))
      end
    end

    context "旧形式 ({id} のみ) のカーソルの場合（後方互換）" do
      it "created_at が nil のハッシュを返す" do
        cursor = Base64.strict_encode64({ id: 100 }.to_json)

        result = described_class.decode(cursor)

        expect(result).to eq(created_at: nil, id: 100)
      end
    end

    context "カーソルが nil または空文字の場合" do
      it "nil の場合 nil を返す" do
        expect(described_class.decode(nil)).to be_nil
      end

      it "空文字の場合 nil を返す" do
        expect(described_class.decode("")).to be_nil
      end
    end

    context "不正なカーソルの場合" do
      it "Base64 として不正なら ValidationError を上げる" do
        expect { described_class.decode("not-base64!@#") }.to raise_error(ValidationError, "invalid cursor")
      end

      it "JSON として不正なら ValidationError を上げる" do
        bad = Base64.strict_encode64("not json")
        expect { described_class.decode(bad) }.to raise_error(ValidationError, "invalid cursor")
      end

      it "id が整数でない場合 ValidationError を上げる" do
        bad = Base64.strict_encode64({ id: "abc" }.to_json)
        expect { described_class.decode(bad) }.to raise_error(ValidationError, "invalid cursor")
      end

      it "id が負の整数の場合 ValidationError を上げる" do
        bad = Base64.strict_encode64({ id: -1 }.to_json)
        expect { described_class.decode(bad) }.to raise_error(ValidationError, "invalid cursor")
      end

      it "created_at が ISO8601 として不正な場合 ValidationError を上げる" do
        bad = Base64.strict_encode64({ created_at: "not-a-date", id: 1 }.to_json)
        expect { described_class.decode(bad) }.to raise_error(ValidationError, "invalid cursor")
      end

      it "created_at が文字列でない場合 ValidationError を上げる" do
        bad = Base64.strict_encode64({ created_at: 12345, id: 1 }.to_json)
        expect { described_class.decode(bad) }.to raise_error(ValidationError, "invalid cursor")
      end
    end
  end

  describe ".apply_to" do
    let(:user) { create(:user) }
    let(:book) { create(:book) }
    let!(:older) { create(:user_book, user: user, book: create(:book), created_at: 3.days.ago) }
    let!(:middle) { create(:user_book, user: user, book: create(:book), created_at: 2.days.ago) }
    let!(:newer) { create(:user_book, user: user, book: create(:book), created_at: 1.day.ago) }
    let(:scope) { UserBook.order(created_at: :desc, id: :desc) }

    context "cursor が nil の場合" do
      it "scope をそのまま返す" do
        expect(described_class.apply_to(scope, table: "user_books", cursor: nil).to_a)
          .to eq([ newer, middle, older ])
      end
    end

    context "新形式カーソル (created_at + id) を渡した場合" do
      it "Tuple 比較で境界より小さいレコードに絞り込む" do
        cursor = { created_at: middle.created_at, id: middle.id }

        result = described_class.apply_to(scope, table: "user_books", cursor: cursor).to_a

        expect(result).to eq([ older ])
      end
    end

    context "旧形式カーソル (created_at が nil) を渡した場合（後方互換）" do
      it "id 単独比較で境界より小さいレコードに絞り込む" do
        cursor = { created_at: nil, id: middle.id }

        result = described_class.apply_to(scope, table: "user_books", cursor: cursor).to_a

        expect(result.map(&:id)).to all(be < middle.id)
      end
    end
  end
end
