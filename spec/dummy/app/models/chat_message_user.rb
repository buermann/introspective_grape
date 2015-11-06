class ChatMessageUser < AbstractAdapter
  belongs_to :chat_message
  belongs_to :user
  has_one    :chat, through: :chat_message

  scope :read, ->{ where('read_at IS NOT NULL' ) }
  scope :unread, ->{ where('read_at IS NULL' ) }

  before_save :author_reads_message
  def author_reads_message
    self.read_at = Time.now if user == chat_message.author
  end

  def read?
    read_at.present?
  end
end
