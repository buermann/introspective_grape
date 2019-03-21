require 'rails_helper'
describe Dummy::UserAPI, type: :request do

  let(:user) { User.last || User.make!}
  let(:company) { Company.last || Company.make! }

  before :all do
    User.destroy_all
    c = Company.make
    u = User.make
    u.roles.push Role.new(ownable: c)
    u.save
  end

  context :index do

    it "should return a list of users" do
      get '/api/v1/users'
      response.should be_successful
      json.length.should == 1
      json.first['id'].to_i.should    == user.id
      json.first['first_name'].should == user.first_name
      json.first['last_name'].should  == user.last_name
      json.first['roles_attributes'].size.should == 1
      json.first['roles_attributes'].first['ownable_type'].should == 'Company'
      json.first['roles_attributes'].first['ownable_id'].should == company.id
    end

    it "should constrain the index by a time range" do
      6.times { User.make! }
      u = User.last
      u.update_column(:created_at, 1.day.ago)
      get '/api/v1/users', params: { created_at_start: 2.day.ago, created_at_end: 8.hours.ago }
      response.should be_successful
      json.length.should eq 1
      json.first['id'].to_i.should    eq u.id
      json.first['first_name'].should eq u.first_name
    end

    it "should accept a comma separated list of ids" do
      4.times { User.make! }
      user_ids = [User.first,User.second,User.third].map(&:id)
      get '/api/v1/users', params: { id: user_ids.join(',') }
      response.should be_successful
      json.length.should eq 3
      json.map {|j| j['id'] }.should eq user_ids
    end

    it "should not expose users' encrypted_passwords" do
      get "/api/v1/users"
      response.should be_successful
      json.first['encrypted_password'].should be_nil
    end
  end


  context :show do
    it "should return the specified user" do
      get "/api/v1/users/#{user.id}"
      response.should be_successful
      json['email'].should == user.email
    end

    it "should not expose a user's encrypted_password" do
      get "/api/v1/users/#{user.id}"
      response.should be_successful
      json['encrypted_password'].should be_nil
    end

    it "should return an error if the user doesn't exist" do
      get "/api/v1/users/#{user.id+1}"
      response.code.should == "404"
    end
  end


  context :create do

    it "should create a user and send the confirmation email" do
      post "/api/v1/users", params: { email: 'email@test.com', password: 'abc12345' }
      response.should be_successful
      json['email'].should == user.email
      User.last.confirmed_at.should == nil
      User.last.confirmation_sent_at.should_not == nil
    end

    it "should create a user and skip the confirmation email" do
      post "/api/v1/users", params: { email: 'email@test.com', password: 'abc12345', skip_confirmation_email: true }
      response.should be_successful
      json['email'].should == user.email
      User.last.confirmed_at.should_not == nil
      User.last.confirmation_sent_at.should == nil
    end

    it "should validate a new user" do
      post "/api/v1/users", params: { email: 'a'*257, password: '' }
      response.code.should == "400"
      json['error'].should == "Email: is invalid, Password: can't be blank"
    end

    it "should return only the records that were created at a nested endpoint" do
      new_company = Company.make!
      post "/api/v1/users/#{user.id}/roles", params:  {ownable_type: 'Company', ownable_id: new_company.id}
      response.should be_successful
      json.size.should eq 1
      json.first['ownable_id'].should eq new_company.id
    end


    let(:params) do
      { email: 'test@test.com', password: 'abc12345', roles_attributes:[] }
    end

    let(:role) do
      { ownable_id: company.id, ownable_type: 'Company' }
    end

    it "should create a company admin" do
      params[:roles_attributes].push(role)
      post "/api/v1/users", params: params
      response.should be_successful
      User.last.admin?(company).should be_truthy
    end


    context "Project default passwords for new users" do
      let(:job)     { Job.make! }
      let(:project) { Project.make!(jobs: [job], default_password: "super secret") }
      let(:params) do
        {
          email: 'test@test.com', password: '',
          user_project_jobs_attributes: [ job_id: project.jobs.first.id, project_id: project.id ]
        }
      end

      it "should set an empty password to an assigned project's default password" do
        post "/api/v1/users", params: params
        response.should be_successful
        json['user_project_jobs_attributes'][0]['name'].should  == project.name
        json['user_project_jobs_attributes'][0]['title'].should == job.title
      end

      it "should return a validation error if the user's assigned project has no default password" do
        project.update_attributes(default_password: nil)
        post "/api/v1/users", params: params
        response.status.should == 400
        json['error'].should == "Password: can't be blank"
      end
    end

  end

  context :update do
    it "should upload a user avatar via the root route" do
      params = { avatar_attributes: { file: Rack::Test::UploadedFile.new(Rails.root+'../fixtures/images/avatar.jpeg', 'image/jpeg', true) } }

      put "/api/v1/users/#{user.id}", params: params

      response.should be_successful
      json['avatar_url'].should eq Image.last.file.url(:medium)
      user.avatar.should     eq Image.last
      user.avatar_url.should eq Image.last.file.url(:medium)
    end

    it "should upload a user avatar via the nested route, to test the restful api's handling of has_one associations" do
      params = { file: Rack::Test::UploadedFile.new(Rails.root+'../fixtures/images/avatar.jpeg', 'image/jpeg', true) }

      post "/api/v1/users/#{user.id}/avatars", params: params

      response.should be_successful
      user.avatar.should     == Image.last
      user.avatar_url.should == Image.last.file.url(:medium)
      user.avatar_url
    end

    it "should require a devise re-confirmation email to update a user's email address" do
      new_email = 'new.email@test.com'
      old_email = user.email
      put "/api/v1/users/#{user.id}", params: { email: new_email }
      response.should be_successful
      user.reload
      user.email.should             == old_email
      user.unconfirmed_email.should == new_email
      json['email'].should == old_email
    end

    it "should skip the confirmation and update a user's email address" do
      new_email = 'new.email@test.com'
      put "/api/v1/users/#{user.id}", params: { email: new_email, skip_confirmation_email: true }
      response.should be_successful
      json['email'].should == new_email
      user.reload
      user.email.should    == new_email
    end

    it "should validate the uniqueness of a user role" do
      put "/api/v1/users/#{user.id}", params: { roles_attributes: [{ownable_type: 'Company', ownable_id: company.id}] }
      response.should_not be_successful
      json['error'].should =~ /user has already been assigned that role/
      user.admin?(company).should be_truthy
    end

    it "should update a user to be company admin" do
      c = Company.make
      c.save!
      put "/api/v1/users/#{user.id}", params: { roles_attributes: [{ownable_type: 'Company', ownable_id: c.id}] }
      response.should be_successful
      user.reload
      user.admin?(c).should be_truthy
    end

    it "should destroy a user's company admin role" do
      user.admin?(company).should be_truthy
      put "/api/v1/users/#{user.id}", params: { roles_attributes: [{id: user.roles.last.id, _destroy: '1'}] }
      response.should be_successful
      user.reload
      user.admin?(company).should be_falsey
    end
  end

end
