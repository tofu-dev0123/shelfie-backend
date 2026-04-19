require "rails_helper"

RSpec.describe HashtagParser do
  describe ".extract" do
    it "英数字・アンダースコアのハッシュタグを抽出する" do
      expect(described_class.extract("I love #Ruby and #Rails_3!")).to eq(%w[Ruby Rails_3])
    end

    it "日本語ハッシュタグを抽出する" do
      expect(described_class.extract("#ミステリー が好き")).to eq([ "ミステリー" ])
    end

    it "重複は1件にまとめる（uniq）" do
      expect(described_class.extract("#Ruby #Ruby #Ruby")).to eq([ "Ruby" ])
    end

    it "大文字小文字は別タグとして扱う" do
      expect(described_class.extract("#SF #sf")).to eq(%w[SF sf])
    end

    it "# 直後が記号だけなら抽出しない" do
      expect(described_class.extract("#!")).to eq([])
      expect(described_class.extract("# ")).to eq([])
    end

    it "50文字を超える連続文字は先頭50文字までに制限される" do
      long_tag = "a" * 60
      expect(described_class.extract("##{long_tag}")).to eq([ "a" * 50 ])
    end

    it "content が nil のとき空配列を返す" do
      expect(described_class.extract(nil)).to eq([])
    end

    it "content が空文字のとき空配列を返す" do
      expect(described_class.extract("")).to eq([])
    end
  end
end
