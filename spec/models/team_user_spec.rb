require 'rails_helper'

RSpec.describe TeamUser, type: :model do

  it "should make a valid instance" do
    TeamUser.make.valid?.should == true
  end

  it "should save a valid instance" do
    TeamUser.make!.should == TeamUser.last
  end

  it "should validate the user belongs to the project" do
    t = TeamUser.make(team: Team.make!, user: User.make!)
    t.valid?.should == false
    t.errors.messages[:user].first.should =~ /is not on the \w+ project/
  end


end
