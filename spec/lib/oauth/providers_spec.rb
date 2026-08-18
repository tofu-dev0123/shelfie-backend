require "rails_helper"

RSpec.describe Oauth::Providers do
  describe ".fetch" do
    context "登録済みのプロバイダ名を渡した場合" do
      it "google はクラスを返す" do
        expect(described_class.fetch("google")).to eq(Oauth::Providers::Google)
      end

      it "github はクラスを返す" do
        expect(described_class.fetch("github")).to eq(Oauth::Providers::Github)
      end
    end

    context "未登録のプロバイダ名を渡した場合" do
      it "UnsupportedProviderError を raise する" do
        expect { described_class.fetch("twitter") }.to raise_error(Oauth::UnsupportedProviderError)
      end
    end
  end
end
