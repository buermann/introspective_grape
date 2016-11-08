require 'rails_helper'

describe Dummy::RoleAPI, type: :request do
  let(:role) { Role.last }
  let(:user) { User.last }

  before :all do
    Role.destroy_all
    User.make!
    Role.make!(user_id: User.last.id, ownable_type: 'SuperUser')
  end

  it 'should return a list of user roles' do
    get '/api/v1/roles'
    response.should be_success
    json.length.should == 1
    json.first['id'].to_i.should == role.id
  end

  it 'should return the specified user role' do
    get "/api/v1/roles/#{role.id}"
    response.should be_success
    json['email'].should == role.email
  end

  it "should return an error if the role doesn't exist" do
    get "/api/v1/roles/#{role.id+1}"
    response.code.should == '404'
  end

  it 'should not duplicate user roles' do
    post '/api/v1/roles', { user_id: user.id, ownable_type: 'SuperUser' }
    response.code.should == '400'
    json['error'].should =~ /user has already been assigned that role/
  end
  
  it 'validates ownable type value specified in grape_validations' do
    post '/api/v1/roles', { user_id: user.id, ownable_type: 'NotSuperUser' }
    response.code.should == '400'
    json['error'].should eq "ownable_type does not have a valid value"
  end
end
