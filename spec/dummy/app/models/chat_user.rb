class ChatUser < AbstractAdapter
  belongs_to :chat
  belongs_to :user 

  alias_attribute :joined_at, :created_at
  alias_attribute :left_at,   :departed_at

  scope :current, ->{ where(departed_at: nil) }

  validate :user_not_already_active, on: :create

  def user_not_already_active
    errors[:base] << "#{user.name} is already present in this chat." if chat.chat_users.where(user_id: user.id, departed_at: nil).count > 0 if user.persisted?
  end

end
