require 'rails_helper'

describe Dummy::LocationAPI, type: :request do
  include LocationHelper

  let(:location) { Location.find_by_name("TEST") }

  before :all do
    create_test_airport
    Location.make!(name: "TEST2", kind: "airport") 
  end


  it "should return an array of camelized location entities" do
    get '/api/v1/locations'
    response.should be_success
    j = JSON.parse(response.body)
    j.each {|l| l.key?('childLocations').should be_truthy }
    j.each {|l| l.key?('parentLocationId').should be_truthy }
    j.each {|l| l.key?('updatedAt').should be_truthy }
    j.each {|l| l.key?('createdAt').should be_truthy }
  end

  it "should return a list of top level locations and their children" do
    get '/api/v1/locations'
    response.should be_success
    json.length.should eq 2
    json.map{|l| l['id'].to_i }.include?(location.id).should == true

    json.first['child_locations'].size.should > 0
    json.first['child_locations'].map{|l| l['id'].to_i}.sort.should == location.child_locations.map(&:id).sort
  end


  it "should generate basic filters on the whitelisted model attributes" do 
    get '/api/v1/locations', { name: "TEST" }
    response.should be_success
    json.length.should eq 1
    json.first['name'].should eq "TEST"
  end

  it "should parse more advanced JSON filters" do
    get '/api/v1/locations', filter: "{\"child_locations_locations\":{\"name\":\"Terminal A\"}}" 
    response.should be_success
    json.length.should eq 1
    json.first['child_locations'].length.should eq 1
    json.first['child_locations'].first['name'].should eq "Terminal A"
  end

  it "should return the specified location" do
    get "/api/v1/locations/#{location.id}"
    response.should be_success
    json['name'].should == location.name
  end

  it "should return an error if the location doesn't exist" do
    get "/api/v1/locations/#{Location.last.id+1}"
    response.code.should == "404"
  end

  it "should create a location" do
    post "/api/v1/locations", { name: 'Test 123', kind: "terminal" } 
    response.should be_success
    json['name'].should == "Test 123"
  end
  
  it "should create a location with a beacon" do
    b = LocationBeacon.make(company: Company.last)
    post "/api/v1/locations", { name: 'Test 123', kind: "gate", beacons_attributes: [ b.attributes ] } 
    response.should be_success
    json['name'].should == "Test 123"
    l   = Location.find(json['id'])
    created = l.beacons.first
    created.uuid.should   == b.uuid.delete('-').upcase
    created.minor.should  == b.minor
    created.major.should  == b.major
  end
 
  it "should create a location with gps coordinates" do
    gps = LocationGps.make
    post "/api/v1/locations", { name: 'Test 123', kind: "airport", gps_attributes: gps.attributes } 
    response.should be_success
    json['name'].should == "Test 123"
    l   = Location.find(json['id'])
    created = l.gps
    # Ruby and Postgres do not share the same floating point precision
    created.lat.round(10).should == gps.lat.round(10)
    created.lng.round(10).should == gps.lng.round(10)
    created.alt.should           == gps.alt
  end
  
  it "should validate a new location" do
    post "/api/v1/locations", { name: 'test' }
    response.code.should == "400"
    json['error'].should == "Kind: is not included in the list"
  end

  it "should update the location" do
    new_name = 'New Test 1234'
    put "/api/v1/locations/#{location.id}", { name: new_name } 
    response.should be_success
    location.reload
    location.name.should == new_name
    json['name'].should == new_name
  end

  it "should validate the location on update" do
    old_kind = location.kind
    put "/api/v1/locations/#{location.id}", { kind: 'bring the noise' }
    response.code.should == "400"
    location.reload
    location.kind.should == old_kind
    json['error'].should == 'Kind: is not included in the list'
  end

  it "should destroy the location and all of its child and grandchild locations" do
    child_locations = location.child_locations.map {|l| [l.id, l.child_locations.map(&:id)] }.flatten
    delete "/api/v1/locations/#{location.id}"
    response.should be_success
    Location.find_by_id(location.id).should == nil
    Location.where(id: child_locations).size.should == 0
  end


end
