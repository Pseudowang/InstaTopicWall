class CreateTopics < ActiveRecord::Migration[8.0]
  def change
    create_table :topics do |t|
      t.string :name
      t.string :hashtag
      t.text :description
      t.datetime :last_refreshed_at

      t.timestamps
    end
  end
end
