class RemoveSeedTagsAndClearTagData < ActiveRecord::Migration[8.1]
  # タグ仕様を「本文中ハッシュタグ＋サジェスト」方式に切り替えるため、
  # シードで固定管理していた tags と、タグに依存するリレーション（user_book_tags / tag_follows）を全削除する。
  # 以降は UserBooks::CreateService / UpdateService が本文をパースして動的に Tag を生成する。
  def up
    execute "TRUNCATE TABLE user_book_tags, tag_follows, tags RESTART IDENTITY CASCADE;"
  end

  def down
    # 削除したシードタグ・関連データは復元できないため、ロールバックは no-op とする
  end
end
