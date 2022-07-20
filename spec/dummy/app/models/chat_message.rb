class ChatMessage < AbstractAdapter
  belongs_to :chat
  belongs_to :author, class_name: 'User'

  has_many :chat_users, through: :chat
  has_many :recipients, lambda {|message|  where(':created_at >= chat_users.created_at and (chat_users.departed_at IS NULL OR :created_at <= chat_users.departed_at)', created_at: message.created_at ) }, through: :chat_users, source: :user, class_name: 'User'

  # Create ChatUserMessage records for each recipient to track read status
  has_many :chat_message_users, dependent: :destroy

  validate :author_in_chat

  def author_in_chat
    errors.add(:base, 'User not in chat session.') unless chat.active_users.include? author
  end

  before_save :create_message_users, if: :new_record?
  def create_message_users
    chat_users.merge(ChatUser.current).each do |cu|
      chat_message_users.build(user: cu.user)
    end
  end

  def read_by?(user)
    chat_message_users.merge(ChatMessageUser.read).map(&:user_id).include?(user.id)
  end

  def self.find_chat_for_users(users)
    # presumably much more efficient ways to run an intersecton, we want to find the last
    # exact match with the users being messaged to append to the existing chat.
    Chat.eager_load(:chat_users).where("chat_users.departed_at IS NULL").order('chats.created_at desc').detect {|c| c.chat_users.map(&:user_id).uniq.sort == users.map(&:id).sort }
  end

end
