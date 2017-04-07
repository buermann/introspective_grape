class Chat < AbstractAdapter
  belongs_to :creator, foreign_key: :creator_id, :class_name => "User", inverse_of: :own_chats

  has_many :chat_users, dependent: :destroy
  has_many :users, through: :chat_users
  has_many :chat_messages, dependent: :destroy
  has_many :messages, class_name: 'ChatMessage', dependent: :destroy

  def active_users
    chat_users.includes(:user).select {|cu| cu.departed_at.nil? }.map(&:user)
  end

  before_create :add_creator_to_conversation
  def add_creator_to_conversation
    users.push creator
  end

end
