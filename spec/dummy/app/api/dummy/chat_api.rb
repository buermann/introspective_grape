class Dummy::ChatAPI < DummyAPI
  Chat.default_includes :chat

  before do 
    authorize!
  end

  resource :chats do  

    desc "list the current user's existing chats" 
    get '/' do
      authorize Chat.new, :index?
      present current_user.chats.includes(:users), with: ChatEntity
    end

    desc "get new chat notifications"
    params {
      optional :id, type: Integer, desc: "Chat ID"
    }
    get '/notifications' do
      authorize Chat.new, :show?
      present current_user.new_messages?(params[:id])
    end


    desc "get messages"
    params {
      optional :id, type: Integer, desc: "Chat ID"
      optional :new, type: Boolean, desc: "Get only new messages"
      optional :mark_as_read, type: Boolean, desc: "Mark new messages as read"
    }
    get '/messages' do
      authorize Chat.new, :show?
      present current_user.read_messages(chat: params[:id], mark_as_read: params[:mark_as_read], new: params[:new]), with: MessageEntity
    end


    desc "list the users in a chat"
    params {
      requires :id, type: Integer, desc: "Chat ID"
    }
    get '/users' do
      authorize Chat.new, :show?
      present current_user.chats.find(params[:id]).active_users, with: UserEntity
    end


    desc "add user(s) to a chat"
    params {
      requires :id, type: Integer, desc: "Chat ID"
      requires :user_ids, desc: 'Comma separated list of User IDs', type: String, regexp: /^\d+(,\d+)*$/
    }
    post '/users' do
      authorize Chat.new, :create?
      user_ids = params[:user_ids].split(',')
      present status: current_user.add_chatters(chat: params[:id], users: user_ids)
    end


    desc "start a new chat"
    params {
      requires :message, type: String
      requires :user_ids, desc: 'Comma separated list of User IDs', type: String, regexp: /^\d+(,\d+)*$/
    }
    post do
      authorize Chat.new, :create?
      user_ids = params[:user_ids].split(',')
      present current_user.chat(users: user_ids, message: params[:message])
    end


    desc "reply to a chat"
    params {
      requires :id, type: Integer, desc: "Chat ID"
      requires :message, type: String
    }
    put ':id' do
      authorize Chat.new, :create?
      current_user.reply(chat: params[:id], message: params[:message])
    end


    desc "drop out of a chat"
    params {
      requires :id, type: Integer, desc: "Chat ID"
    }
    delete ':id' do
      authorize Chat.new, :create?
      present status: current_user.leave_chat(params[:id])
    end
  end


  class UserEntity < Grape::Entity
    expose :id, :name, :email, :avatar_url
  end

  class ChatEntity < Grape::Entity
    expose :id, :creator_id
    expose :users, using: UserEntity
  end

  class MessageEntity < Grape::Entity
    expose :id, :chat_id, :message
    expose :author, using: UserEntity
  end 

end
