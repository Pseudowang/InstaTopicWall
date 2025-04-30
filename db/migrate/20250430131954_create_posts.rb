class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string :instagram_id
      t.text :caption
      t.string :media_url
      t.datetime :timestamp
      t.string :permalink
      t.references :topic, null: false, foreign_key: true
      t.string :media_type
      t.string :username
      t.string :profile_picture_url
      t.string :id_prefile

      t.timestamps
    end
    add_index :posts, :instagram_id, unique: true
  end
end
