require 'rails_helper'
describe GrapeSwagger, type: :request do

  context :swagger_doc do

    it "should render swagger docs for the api" do 
      get '/api/v1/swagger_doc'
      response.should be_success
      json =  JSON.parse( response.body )
      json['apiVersion'].should == 'v1'
    end
  end

end
