class CreateChats < ActiveRecord::Migration
  def change
    create_table :chats do |t|
      t.integer :creator_id, references: :users, foreign_key: false

      t.timestamps null: false
    end
  end
end
