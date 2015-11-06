require 'rails_helper'

RSpec.describe Project, type: :model do

  it "should make a valid instance" do 
    Project.make.valid?.should == true
  end

  it "should save a valid instance" do 
    Project.make!.should == Project.last
  end

  it "should be owned by a company" do 
    Project.make.owner.kind_of?(Company).should == true
  end

end
