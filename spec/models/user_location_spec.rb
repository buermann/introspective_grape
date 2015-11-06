require 'rails_helper'

RSpec.describe UserLocation, type: :model do
  include LocationHelper
  before :all do
    create_test_airport
  end

  let(:user) { User.make! }

  it "validates the detectable type" do 
    ul = UserLocation.new(user: user, location: Location.last, detectable: Location.last, coords: rand_coords)
    ul.valid?.should == false
    ul.errors[:detectable_type].should == ["is not included in the list"]
  end

  it "logs a user's locations by beacon" do
    beacon = LocationBeacon.last
    p1 = user.user_locations.build(location: beacon.location, detectable: beacon, coords: rand_coords)
    user.save.should == true
    p2 = user.user_locations.build(location: beacon.location, detectable: beacon, coords: rand_coords)
    user.save.should == true
    user.user_locations.first.should == p2
  end

  it "logs a user's beacon location by gps" do
    gps = LocationGps.last
    p1 = user.user_locations.build(location: gps.location, detectable: gps, coords: rand_coords)
    user.save.should == true
    p2 = user.user_locations.build(location: gps.location, detectable: gps, coords: rand_coords)
    user.save.should == true
    user.user_locations.first.should == p2
  end

end
