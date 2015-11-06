require 'rails_helper'

RSpec.describe Locatable, type: :model do

  it "validates the locatable type" do
    l = Locatable.make(locatable: User.make)
    l.valid?.should == false
    l.errors.messages.should == {:locatable_type=>["is not included in the list"]}
  end
end
