class CreateChatMessages < ActiveRecord::Migration
  def change
    create_table :chat_messages do |t|
      t.references :chat, chat: true, index: true, foreign_key: true
      t.integer :author_id, references: :users, index: true, foreign_key: false
      t.text :message

      t.timestamps null: false
    end
  end
end
