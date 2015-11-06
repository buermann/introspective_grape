require 'rails_helper'

RSpec.describe Chat, type: :model do
  let(:sender) { User.make! }
  let(:target) { User.make! }
  let(:target2) { User.make! }

  context "a user sends a single chat" do
    it "to one target and both sender and reciever can see it" do
      c = sender.own_chats.build(users: [target])
      c.save
      c.messages.push ChatMessage.new(author: sender, message: 'Hey there. I need you at G1')
      c.save!

      sender.messages.size.should  == 1
      target.messages.size.should  == 1
      target2.messages.size.should == 0
    end

    it "to two targets and both sender and all recievers can see it" do
      c = sender.own_chats.build(users: [target,target2])
      c.save
      c.messages.push ChatMessage.new(author: sender, message: 'Hey there. I need you at G1')
      c.save!

      sender.messages.size.should  == 1
      target.messages.size.should  == 1
      target2.messages.size.should == 1
    end
  end

end
