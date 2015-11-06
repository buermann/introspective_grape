class CreateChatMessageUsers < ActiveRecord::Migration
  def change
    create_table :chat_message_users do |t|
      t.references :chat_message, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: false
      t.timestamp :read_at

      t.timestamps null: false
    end
  end
end
