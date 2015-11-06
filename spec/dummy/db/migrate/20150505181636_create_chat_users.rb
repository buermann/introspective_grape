class CreateChatUsers < ActiveRecord::Migration
  def change
    create_table :chat_users do |t|
      t.references :chat, chat: true, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: false
      t.datetime :departed_at

      t.timestamps null: false
    end
  end
end
