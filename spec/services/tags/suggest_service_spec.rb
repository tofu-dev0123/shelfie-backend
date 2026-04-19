require "rails_helper"

RSpec.describe Tags::SuggestService do
  describe ".call" do
    context "正常系" do
      before do
        create(:tag, name: "Ruby")
        create(:tag, name: "Rust")
        create(:tag, name: "TypeScript")
        create(:tag, name: "script")
        create(:tag, name: "Kubernetes")
      end

      it "部分一致したタグのみを返す" do
        result = described_class.call(q: "Ru")
        expect(result.map(&:name)).to contain_exactly("Ruby", "Rust")
      end

      it "前方一致を部分一致より優先して並べる" do
        result = described_class.call(q: "script")
        # "script" は前方一致、"TypeScript" は途中一致
        expect(result.map(&:name)).to eq(%w[script TypeScript])
      end

      it "大文字小文字を区別しない（ILIKE）" do
        result = described_class.call(q: "ruby")
        expect(result.map(&:name)).to include("Ruby")
      end

      it "SUGGEST_LIMIT 件までしか返さない" do
        Tag.delete_all
        12.times { |i| create(:tag, name: "pre#{i}") }
        result = described_class.call(q: "pre")
        expect(result.size).to eq(TagConstants::SUGGEST_LIMIT)
      end
    end

    context "異常系" do
      it "q が空文字のとき ValidationError を raise する" do
        expect { described_class.call(q: "") }.to raise_error(ValidationError)
      end

      it "q が nil のとき ValidationError を raise する" do
        expect { described_class.call(q: nil) }.to raise_error(ValidationError)
      end

      it "q が MAX_QUERY_LENGTH 超のとき ValidationError を raise する" do
        expect { described_class.call(q: "a" * (TagConstants::MAX_QUERY_LENGTH + 1)) }
          .to raise_error(ValidationError)
      end
    end
  end
end
