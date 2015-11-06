module User::Chatter

  def message_query(chat_id: chat_id, new: true)
    messages.joins(:chat_message_users) 
    .where('chat_message_users.user_id'=> id)
    .where(new ? {'chat_message_users.read_at'=>nil} : '')
    .where(chat_id ? {'chat_messages.chat_id'=> chat_id} : '')
    .order('') # or it will add an order by id clause that breaks the count query.
  end

  def new_messages?(chat=nil) # returns a hash of chat_ids with new message counts 
    chat_id = chat.kind_of?(Chat) ? chat.id : chat
    new = message_query(chat_id: chat_id, new: true)
          .select("chat_messages.chat_id, count(chat_messages.id) as count")
          .group('chat_id')

    chat ? { chat_id => new.first.try(:count)||0 } : Hash[new.map {|c| [c.chat_id, c.count]} ]
  end

  def read_messages(chat: nil, mark_as_read: false, new: true)
    chat_id = chat.kind_of?(Chat) ? chat.id : chat
    new = message_query(chat_id: chat_id, new: new).order('chat_messages.created_at').includes(:author) # :chat?
    new.map(&:chat).uniq.each {|chat| mark_as_read(chat) } if mark_as_read
    new
  end

  def chat(users: users, message: message)
    users = [users].flatten
    users = users.first.kind_of?(User) ? users : User.where(id: users)
    chat  = Chat.create(creator: self)
    chat.users.push users
    chat.messages.build(message: message, author: self)
    chat.save! 
    chat
  end

  def reply(chat: chat, message: message)
    chat = chat.kind_of?(Chat) ? chat : Chat.find(chat)
    mark_as_read(chat) # a reply implies that the thread has been read
    chat.messages.build(message: message, author: self)
    chat.save!
    chat
  end

  def add_chatters(chat: chat, users: users)
    users = [users].flatten
    users = users.first.kind_of?(User) ? users : User.where(id: users)
    chat  = chat.kind_of?(Chat) ? chat : Chat.find(chat)

    if chat.active_users.include?(self) # only current participants can add new users
      chat.users.push users
      chat.messages.build(chat: chat, author: self, message: "#{self.name} [[ADDED_USER_MESSAGE]] #{users.map(&:name).join(',')}")
      chat.save!
    else 
      chat.errors[:base] << "Only current chat participants can add users."
      raise ActiveRecord::RecordInvalid.new(chat)
    end
  end

  def leave_chat(chat)
    chat = chat.kind_of?(Chat) ? chat : Chat.find(chat)

    if chat.active_users.include?(self)
      reply(chat:chat, message: "#{name} [[DEPARTS_MESSAGE]]")
      chat.chat_users.detect {|cu| cu.user_id == self.id}.update_attributes(departed_at: Time.now)
    else
      true
    end
  end

  def mark_as_read(chat)
    ChatMessageUser.joins(:chat_message).where('read_at IS NULL AND chat_messages.chat_id = ? AND user_id = ?', chat.id, id).update_all(read_at: Time.now)
  end

  def mark_messages_as_read(messages)
    chat_message_users.where("chat_message_id in (?) and read_at IS NULL", messages.map(&:id)).update_all(read_at: Time.now)
  end

end
