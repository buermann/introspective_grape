require 'rails_helper'
describe Dummy::Sessions, type: :request do
  @without_authentication = true

  before :all do
    @without_authentication = true
    User.make!
  end

  let(:user) { User.last }

  context :sign_in do

    it "should set a user token on login" do
      post '/api/v1/sessions', { login: user.email, password: 'abc12345', token: true }
      response.should be_success
      json['id'].to_i.should == user.id
      json['email'].should == user.email
      json['authentication_token'].should be_truthy
    end

    it "should not set a token if the login fails" do
      post '/api/v1/sessions', { login: user.email, password: 'bad password', token: true }
      response.should_not be_success
      json['error'].should be_truthy
      json['error']['type'].should == 'unauthenticated'
      user.authentication_token.should be_nil
    end
  end

  context :sign_out do
    it "should reset a user's auth token" do
      user.authentication_token = "1234567890"
      user.save!
      delete "/api/v1/sessions", { api_key: "1234567890" }
      response.should be_success
      user.reload
      user.authentication_token.should be_nil
    end

    it "signing out an already signed-out user should look fine, right?" do
      user.authentication_token = "1234567890"
      user.save!
      delete "/api/v1/sessions", { api_key: "1234567890" }
      response.should be_success
      user.reload
      user.authentication_token.should be_nil
      delete "/api/v1/sessions", { api_key: "1234567890" }
      response.should be_success
      user.reload
      user.authentication_token.should be_nil
    end
  end

end
