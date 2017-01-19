require 'rails_helper'
describe GrapeSwagger, type: :request do

  context :swagger_doc do

    it "should render swagger docs for the api" do 
      get '/api/v1/swagger_doc'
      response.should be_success
      json =  JSON.parse( response.body )
      json['paths'].map {|p| p[1].values }.flatten.map{|p| p['parameters']}.flatten.compact.map{|p| p['name']}.each do |name|
        name.should eq name.camelize(:lower).gsub(/Destroy/,'_destroy')
      end
    end
  end

end
