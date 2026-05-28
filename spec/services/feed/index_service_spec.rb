require "rails_helper"

RSpec.describe Feed::IndexService, type: :service do
  describe ".call" do
    context "ログインユーザー" do
      let(:user) { create(:user) }
      let(:followee) { create(:user) }
      let(:non_followed) { create(:user) }

      before do
        create(:follow, follower: user, followee: followee)
      end

      it "フォロー中ユーザーと自分の投稿のみを返す" do
        own = create(:user_book, user: user, content: "自分")
        followed = create(:user_book, user: followee, content: "フォロー中")
        create(:user_book, user: non_followed, content: "フォロー外")

        result = described_class.call(current_user: user)

        ids = result[:items].map { |i| i[:id] }
        expect(ids).to contain_exactly(own.id, followed.id)
      end

      it "フォロー0人の場合、自分の投稿のみを返す" do
        user_without_follows = create(:user)
        own = create(:user_book, user: user_without_follows)
        create(:user_book, user: create(:user))

        result = described_class.call(current_user: user_without_follows)

        expect(result[:items].map { |i| i[:id] }).to eq([ own.id ])
      end

      it "created_at DESC + id DESC で並ぶ" do
        older = create(:user_book, user: user, created_at: 2.days.ago)
        newer = create(:user_book, user: user, created_at: 1.day.ago)

        result = described_class.call(current_user: user)

        expect(result[:items].map { |i| i[:id] }).to eq([ newer.id, older.id ])
      end
    end

    context "未ログイン" do
      it "全ユーザーの投稿を返す" do
        ub1 = create(:user_book)
        ub2 = create(:user_book)

        result = described_class.call(current_user: nil)

        expect(result[:items].map { |i| i[:id] }).to contain_exactly(ub1.id, ub2.id)
      end
    end

    context "ページネーション" do
      let(:user) { create(:user) }

      it "limit+1 件取れる場合 has_next=true と next_cursor を返す" do
        books = create_list(:user_book, 3, user: user)

        result = described_class.call(current_user: user, limit: 2)

        expect(result[:items].size).to eq(2)
        expect(result[:pagination][:has_next]).to eq(true)
        expect(result[:pagination][:next_cursor]).not_to be_nil
        decoded = CompoundCursor.decode(result[:pagination][:next_cursor])
        expect(decoded[:id]).to eq(result[:items].last[:id])
        expect(decoded[:created_at]).not_to be_nil
        # 新しい順に取れるので最新2件（books[2], books[1]）
        expect(result[:items].map { |i| i[:id] }).to eq([ books[2].id, books[1].id ])
      end

      it "cursor で次ページが取れる" do
        books = create_list(:user_book, 3, user: user)
        cursor = CompoundCursor.encode(created_at: books[2].created_at, id: books[2].id)

        result = described_class.call(current_user: user, cursor: cursor, limit: 2)

        expect(result[:items].map { |i| i[:id] }).to eq([ books[1].id, books[0].id ])
        expect(result[:pagination][:has_next]).to eq(false)
      end

      it "旧形式カーソル ({id} のみ) でも次ページが取れる（後方互換）" do
        books = create_list(:user_book, 3, user: user)
        legacy_cursor = Base64.strict_encode64({ id: books[2].id }.to_json)

        result = described_class.call(current_user: user, cursor: legacy_cursor, limit: 2)

        expect(result[:items].map { |i| i[:id] }).to eq([ books[1].id, books[0].id ])
        expect(result[:pagination][:has_next]).to eq(false)
      end

      it "同一秒に作成されたレコードでも境界が一意に決まる（複合キー比較）" do
        same_time = 1.day.ago
        b1 = create(:user_book, user: user, created_at: same_time)
        b2 = create(:user_book, user: user, created_at: same_time)
        b3 = create(:user_book, user: user, created_at: same_time)

        first = described_class.call(current_user: user, limit: 2)
        # created_at が同じなので id 降順で b3, b2 を返す
        expect(first[:items].map { |i| i[:id] }).to eq([ b3.id, b2.id ])
        expect(first[:pagination][:has_next]).to eq(true)

        second = described_class.call(current_user: user, cursor: first[:pagination][:next_cursor], limit: 2)
        # b2 の続きで b1 のみを返す（b2 自身は含まれない）
        expect(second[:items].map { |i| i[:id] }).to eq([ b1.id ])
      end

      it "上限50超はクランプされる" do
        create_list(:user_book, 1, user: user)

        expect(Queries::FeedQuery).to receive(:call).with(hash_including(limit: 50)).and_call_original
        described_class.call(current_user: user, limit: 100)
      end

      it "0以下はデフォルト値20" do
        expect(Queries::FeedQuery).to receive(:call).with(hash_including(limit: 20)).and_call_original
        described_class.call(current_user: user, limit: 0)
      end
    end

    context "カーソル不正" do
      it "不正な cursor で ValidationError を投げる" do
        expect {
          described_class.call(current_user: nil, cursor: "invalid!!!")
        }.to raise_error(ValidationError)
      end
    end

    context "レスポンス形式" do
      let(:user) { create(:user) }

      it "items に必要なフィールドが含まれる" do
        book = create(:book)
        user_book = create(:user_book, user: user, book: book, content: "本文")
        tag_a = create(:tag, name: "Architecture")
        tag_g = create(:tag, name: "Go")
        create(:user_book_tag, user_book: user_book, tag: tag_g)
        create(:user_book_tag, user_book: user_book, tag: tag_a)

        result = described_class.call(current_user: user)

        item = result[:items].first
        expect(item[:id]).to eq(user_book.id)
        expect(item[:content]).to eq("本文")
        expect(item[:tags]).to eq([ "Architecture", "Go" ])
        expect(item[:book][:isbn]).to eq(book.isbn)
        expect(item[:user][:username]).to eq(user.username)
      end
    end
  end
end
