require 'rails_helper'

RSpec.describe Team, type: :model do

  it "should make a valid instance" do
    Team.make.valid?.should == true
  end

  it "should save a valid instance" do
    Team.make!.should == Team.last
  end

  it "should be created by a user" do
    Team.make.creator.kind_of?(User).should == true
  end

end
