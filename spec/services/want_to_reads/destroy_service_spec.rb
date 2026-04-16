require "rails_helper"

RSpec.describe WantToReads::DestroyService, type: :service do
  let(:user) { create(:user) }
  let(:isbn) { "9784873116068" }

  describe ".call" do
    context "正常系" do
      context "読みたいリストに書籍が存在する場合" do
        let!(:book) { create(:book, isbn: isbn) }
        let!(:want_to_read) { create(:want_to_read, user: user, book: book) }

        it "WantToRead レコードが削除される" do
          expect { described_class.call(current_user: user, isbn: isbn) }
            .to change(WantToRead, :count).by(-1)
        end
      end

      context "読みたいリストに書籍が存在しない場合（冪等）" do
        let!(:book) { create(:book, isbn: isbn) }

        it "エラーにならず何も変化しない" do
          expect { described_class.call(current_user: user, isbn: isbn) }
            .not_to change(WantToRead, :count)
        end
      end

      context "DB に書籍自体が存在しない場合（冪等）" do
        it "エラーにならず何も変化しない" do
          expect { described_class.call(current_user: user, isbn: isbn) }
            .not_to change(WantToRead, :count)
        end
      end
    end

    context "異常系" do
      it "isbn が13桁の数字でないとき ValidationError を raise する" do
        expect { described_class.call(current_user: user, isbn: "invalid") }
          .to raise_error(ValidationError)
      end
    end
  end
end
