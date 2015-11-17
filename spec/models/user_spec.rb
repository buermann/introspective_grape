require 'rails_helper'
include ActionDispatch::TestProcess # -> fixture_file_upload

RSpec.describe User, type: :model do
  context 'User::Chatter' do 

    def user(email)
      User.find_by_email(email) || User.make!(email: email) 
    end

    it "uploads an avatar to AWS" do 
      u = User.make
      u.avatar = Image.new(file: fixture_file_upload( Rails.root+'../fixtures/images/exif.jpeg'))
      u.save
      u.avatar.file_processing?.should == false
      
      #u.avatar_url.should            =~ /medium\/exif.jpeg/
      #u.avatar_url(:original).should =~ /original\/exif.jpeg/
      #u.avatar_url(:thumb).should    =~ /thumb\/exif.jpeg/
    end

    context "chatting" do 
      let(:sender) {  user('sender@springshot.com') }
      let(:target) {  user('target1@springshot.com') }
      let(:target2) { user('target2@springshot.com') }
      let(:target3) { user('target3@springshot.com') }

      let(:discussion) {
        c = sender.chat([target,target2], 'Hey guys')
        target2.reply( c, "What's up?")
        c 
      }


      before :all do 
        Chat.destroy_all
      end

      it "chatting a user returns a chat" do 
        c = sender.chat(target, 'a private message')
        c.kind_of?(Chat).should be_truthy
      end

      it "a user sees that she has new messages in a discussion" do 
        discussion.save! # invoke create hooks on ChatMessage for ChatMessageUser
        sender.new_messages?(discussion)[discussion.id].should == 1
        target2.new_messages?(discussion)[discussion.id].should == 0
        target.new_messages?(discussion)[discussion.id].should == 2
      end

      it "a user gets notifications for all new messages for all conversations" do
        discussion.save!
        chat2 = target.chat( [target2], "Come to E2")
        target.reply( chat2, "Hurry")

        target2.new_messages?[discussion.id].should == nil
        target2.new_messages?[chat2.id].should == 2
      end

      it "a user sees her new messages" do 
        discussion.save!

        sender.read_messages.size.should == 1
        sender.read_messages[0].message.should == "What's up?"

        target.read_messages.size.should == 2
        target.read_messages(discussion)[0].message.should == "Hey guys"
        target.read_messages(discussion)[1].message.should == "What's up?"

        target2.read_messages.size.should == 0
        #target2.new_messages[0].message.should == "Hey guys"
      end

      it "users are notified when a new user is added to the chat" do
        target2.add_chatters(discussion, target3)

        sender.messages.last.message.should =~ /ADDED_USER/
          target.messages.last.message.should =~ /ADDED_USER/
          target2.messages.last.message.should =~ /ADDED_USER/
          target3.messages.last.message.should =~ /ADDED_USER/
      end

      it "when a user drops out should not see subsequent messages" do
        discussion.active_users.size.should == 3
        target.leave_chat(discussion).should == true
        # and if the user has left leaving again should register as a success
        target.leave_chat(discussion).should == true
        discussion.active_users.size.should == 2
        sender.reply(discussion, 'I never liked target anyway.')

        sender.messages.last.message.should == 'I never liked target anyway.'
        target2.messages.last.message.should == 'I never liked target anyway.'

        target.messages.last.message.should_not == 'I never liked target anyway.'
        target.messages.last.message.should =~ /DEPARTS/
      end

      it "a user rejoins a chat and doesn't see messages while they were gone" do
        target2.leave_chat(discussion)
        sender.reply(discussion, "Where'd target2 go?")
        sender.add_chatters( discussion, target2)

        messages = target2.messages.order('created_at').map(&:message)
        messages.include?("Where'd target2 go?").should be_falsey
        messages.last.should =~ /ADDED_USER/
      end

      it "when a user reads a message it should mark the message as read" do
        discussion.save!
        target.chat_message_users.unread.size.should == 2
        target.mark_messages_as_read(target.messages)
        target.chat_message_users.unread.size.should == 0
      end

      it "should cascade deletes to chat_user, messages, and read logs" do
        ChatUser.where(discussion.id).size.should == 3
        ChatMessage.where(discussion.id).size.should == 2
        discussion.destroy
        ChatUser.where(discussion.id).size.should == 0
        ChatMessage.where(discussion.id).size.should == 0
      end
    end
  end

end
