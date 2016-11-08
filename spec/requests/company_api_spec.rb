require 'rails_helper'

describe Dummy::CompanyAPI, type: :request do
  context :default_values do
    it "should respect default values" do
      get '/api/v1/companies/special/list'
      response.should be_success
      json.should eq({"boolean_default"=>false, "string_default"=>"foo", "integer_default"=>123})
    end

    it "should override default values" do
      get '/api/v1/companies/special/list', boolean_default: true, string_default: 'bar', integer_default: 321
      response.should be_success
      json.should eq({"boolean_default"=>true, "string_default"=>"bar", "integer_default"=>321})
    end
  end

  context :pagination do
    it "should use the default introsepctive grape pagination values" do
      Company.destroy_all
      30.times { Company.make! }

      get '/api/v1/companies'

      response.should be_success
      json.length.should eq 25
      json.first['id'].should eq Company.first.id
      response.headers.slice("X-Total", "X-Total-Pages", "X-Per-Page", "X-Page", "X-Next-Page", "X-Prev-Page", "X-Offset").values.should eq ["30", "2", "25", "1", "2", "", "0"]
    end
  end

  before :all do
    Company.find_by_name("Sprockets") || Company.make!(name:"Sprockets")
  end

  let(:company) { Company.find_by_name("Sprockets") }

  it "should return a list of companies" do
    get '/api/v1/companies'
    response.should be_success
    json.length.should > 0
    json.map{|c| c['id'].to_i}.include?(company.id).should == true
  end

  it "should return the specified company" do
    get "/api/v1/companies/#{company.id}"
    response.should be_success
    json['name'].should == company.name
  end

  it "should return an error if the company doesn't exist" do
    get "/api/v1/companies/#{Company.last.id+1}"
    response.code.should == "404"
  end


  it "should create a company" do
    post "/api/v1/companies", { name: 'Test 123', short_name: 'T123' } 
    response.should be_success
    json['name'].should       == "Test 123"
    json['short_name'].should == "T123"
  end
  
  it "should validate a new company" do
    post "/api/v1/companies", { name: 'a'*257, short_name: 'a'*11 }
    response.code.should == "400"
    json['error'].should == "Name: is too long (maximum is 256 characters), Short Name: is too long (maximum is 10 characters)"
  end


  it "should update the company" do
    new_name = 'New Test 1234'
    put "/api/v1/companies/#{company.id}", { name: new_name } 
    response.should be_success
    company.reload
    company.name.should == new_name
    json['name'].should == new_name
  end

  it "should validate the company on update" do
    old_name = company.name
    put "/api/v1/companies/#{company.id}", { name: 'a'*257, short_name: 'a'*11 }
    response.code.should == "400"
    company.reload
    company.name.should == old_name
    json['error'].should == "Name: is too long (maximum is 256 characters), Short Name: is too long (maximum is 10 characters)"
  end

  it "should validate json parameters" do
    put "/api/v1/companies/#{company.id}", { gizmos: "garbage" }
    json["error"].should eq "gizmos must be valid JSON!" 
  end

  it "should validate json array parameters" do
    put "/api/v1/companies/#{company.id}", { widgets: "[garbage[\"A\",\"B\"]" }
    json["error"].should eq "widgets must be valid JSON array!"
  end

  it "should validate json hash parameters" do
    put "/api/v1/companies/#{company.id}", { sprockets: "{\"foo\":\"bar\"}garbage}" }
    json["error"].should eq "sprockets must be valid JSON hash!"
  end

end
