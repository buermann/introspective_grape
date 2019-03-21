require 'rails_helper'
describe Dummy::RoleAPI, type: :request do
  let(:role) { Role.last }
  let(:user) { User.last }
  let(:company) { Company.last }

  before :all do
    c = Company.make!
    Role.destroy_all
    User.make!(superuser: true)
    Role.make!(user_id: User.last.id, ownable_id: c.id, ownable_type: c.class)
  end

  it 'should return a list of user roles' do
    get '/api/v1/roles'
    response.should be_successful
    json.length.should == 1
    json.first['id'].to_i.should == role.id
  end

  it 'should return the specified user role' do
    get "/api/v1/roles/#{role.id}"
    response.should be_successful
    json['email'].should == role.email
  end

  it "should return an error if the role doesn't exist" do
    get "/api/v1/roles/#{role.id+1}"
    response.code.should == '404'
  end

  it 'should not duplicate user roles' do
    post '/api/v1/roles', params: { user_id: user.id, ownable_type: 'Company', ownable_id: company.id }
    response.code.should == '400'
    json['error'].should =~ /user has already been assigned that role/
  end

  it 'validates ownable type value specified in grape_validations' do
    post '/api/v1/roles', params: { user_id: user.id, ownable_type: 'NotCompany' }
    response.code.should == '400'
    json['error'].should eq "ownable_type does not have a valid value"
  end
end
