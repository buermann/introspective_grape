require "rails_helper"
describe Dummy::ChatAPI, type: :request do

  before :all do
    User.destroy_all
    @without_authentication = true

    @current_user = User.make!(email: "current_user@springshot.com")
    @sender = User.make!(email: "sender@springshot.com")
    @lurker = User.make!(email: "lurker@springshot.com")

    @lurk = @sender.chat( @lurker, "Private conversation.")
    @lurker.reply(@lurk, "the lurker has his own conversation that we don't want the current_user to see anywhere")

    @pm = @sender.chat( @current_user, "Private conversation.")
    @sender.reply(@pm, "I'm asking a question?")
    @sender.reply(@pm, "you there?")

    @chat = @sender.chat( [@lurker,@current_user], "We need to talk.")
    @current_user.reply(@chat, "Is this about tough love?")
  end

  context "while current_user is the current user" do

    before :each do
      @chat.reload
      Grape::Endpoint.before_each do |endpoint|
        allow(endpoint).to receive(:current_user) { @current_user }
      end
    end

    it "should return a list of a user's chats" do
      get "/api/v1/chats"
      response.should be_success
      json.size.should == 2
      json.first['creator_id'].to_i.should == @sender.id
      json.first['users'].size.should == Chat.find(json.first['id']).users.size
    end

    context :notifications do
      it "should get new chat notifications" do
        get "/api/v1/chats/notifications/"
        response.should be_success
        json.keys.size.should     == 1
        json[@pm.id.to_s].should   == 3
      end

      it "should get new chat notifications for a particular chat" do
        get "/api/v1/chats/notifications/", id: @pm.id
        response.should be_success
        json[@pm.id.to_s].should == 3
      end

      it "should return 0 for non-existent chats" do
        get "/api/v1/chats/notifications/", id: 0
        response.should be_success
        json['0'].should == 0
      end
    end

    context :messages do

      it "should get no new chat messages if user was last to reply" do
        get "/api/v1/chats/messages", id: @chat.id, new: true
        response.should be_success
        json.size.should == 0
      end

      it "should get new chat messages if user recieves another reply" do
        @sender.reply(@chat, "And now for something completely different.")
        get "/api/v1/chats/messages", id: @chat.id, new: true
        response.should be_success
        json.size.should == 1
      end

      it "should mark all new messages from all chats as read if mark_as_read is true" do
        @sender.reply(@chat, 'A new response.')
        @current_user.new_messages?.keys.size.should == 2
        get "/api/v1/chats/messages", new: true, mark_as_read: true
        response.should be_success
        json.size.should == 4
        @current_user.new_messages?.keys.size.should == 0
      end
    end


    context :users do
      it "should list the users in a chat" do
        get "/api/v1/chats/users", id: @chat.id
        response.should be_success
        json.size.should == 3
        json.map{|u| u['email']}.sort.should == [ "current_user@springshot.com", "lurker@springshot.com", "sender@springshot.com" ]
      end

      it "should add a new user to a chat" do
        new_user1 = User.make
        new_user1.save!
        post "/api/v1/chats/users", id: @chat.id, user_ids: new_user1.id
        response.should be_success
        json['status'].should == true
        @chat.reload
        @chat.active_users.include?(new_user1).should == true
      end

      it "should add new users to a chat" do
        new_user1 = User.make
        new_user2 = User.make
        new_user1.save!
        new_user2.save!
        post "/api/v1/chats/users", id: @chat.id, user_ids: "#{new_user1.id},#{new_user2.id}"
        response.should be_success
        json['status'].should == true
        @chat.reload
        @chat.active_users.include?(new_user1).should == true
        @chat.active_users.include?(new_user2).should == true
      end

      it "should be invalid to add an already active chat member to a chat" do
        @chat.chat_users.size.should == 3
        post "/api/v1/chats/users", id: @chat.id, user_ids: @chat.active_users.first.id
        response.status.should == 400
        json['error'].should == "#{@chat.active_users.first.name} is already present in this chat."
        @chat.reload
        @chat.chat_users.size.should == 3
      end

      it "should raise an error when an outsider tries to add themselves to a chat" do
        post "/api/v1/chats/users", id: @lurk.id, user_ids: @current_user.id
        response.status.should == 400
        json['error'].should == 'Only current chat participants can add users.'
        @lurk.reload
        @lurk.active_users.include?(@current_user).should == false
      end

    end

    context :chat do
      it "should start a new chat" do
        post "/api/v1/chats", user_ids:@lurker.id, message: 'a new chat'
        response.should be_success
        json['creator_id'].should == @current_user.id
        Chat.last.creator.should == @current_user
        Chat.last.messages.map(&:message).first.should == 'a new chat'
        @lurker.read_messages(Chat.last.id ).last.message.should == 'a new chat'
      end

      it "should reply to a chat" do
        put "/api/v1/chats/#{@chat.id}", message: 'A reply.'
        response.should be_success
        ChatMessage.last.author.should == @current_user
        @sender.read_messages(Chat.last.id ).last.message.should == 'A reply.'
        @lurker.read_messages(Chat.last.id ).last.message.should == 'A reply.'
      end

      it "should leave a chat" do
        delete "/api/v1/chats/#{@chat.id}"
        response.should be_success
        json['status'].should == true
        @chat.reload
        @chat.active_users.include?(@current_user).should == false
      end

      it "should only allow chat participants to reply" do
        @current_user.leave_chat(@chat)
        @current_user.reload
        put "/api/v1/chats/#{@chat.id}", message: "I'm an interloper"
        response.status.should == 400
        json['error'].should == 'Messages: is invalid'
        @chat.messages.last.should_not == "I'm an interloper"
      end
    end
  end

end
