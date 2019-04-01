require 'rails_helper'

describe Dummy::ProjectAPI, type: :request do
  before :all do
    [User,Project,Company,Location].map(&:destroy_all)
    cm = User.make!(email:'company.admin@springshot.com')
    pm = User.make!(email:'project.admin@springshot.com')

    2.times {  Project.make! }

    c = Company.make!(name:"Sprockets")
    p = Project.make!(name:"Manufacture Sprockets", owner: c)
        Project.make!(name:"Disassemble Sprockets", owner: c)

    cm.admin_companies.push c
    pm.admin_projects.push p

    cm.save!
    pm.save!
  end

  let(:company) { Company.find_by_name("Sprockets") }
  let(:project) { Project.find_by_name("Manufacture Sprockets") }

  context "As a super admin" do
    it "should return a list of all projects" do
      get '/api/v1/projects', params: { per_page: 10, offset: 0 }
      response.should be_successful
      json.length.should == Project.count
      json.map{|c| c['id'].to_i}.include?(project.id).should == true
    end

    it "should return the specified project" do
      get "/api/v1/projects/#{project.id}"
      response.should be_successful
      json['name'].should == project.name
    end

    it "should return an error if the project doesn't exist" do
      get "/api/v1/projects/#{Project.last.id+1}"
      response.code.should == "404"
    end

    context "edit a project team" do

      before(:each) do
        @team = Team.make!(project: project)
        @u1 = User.make!
        @u2 = User.make!
        UserProjectJob.make!(project: project, job: project.jobs.first, user: @u1)
        UserProjectJob.make!(project: project, job: project.jobs.first, user: @u2)
      end

      context "via nested attributes" do
        it "should create a team with users" do
          p = {
            name: 'New Team', team_users_attributes: [{ user_id: @u1.id }, { user_id: @u2.id }]
          }
          post "/api/v1/projects/#{project.id}/teams", params: p
          response.should be_successful
          Team.last.name.should == 'New Team'
          Team.last.users.to_a.should == [@u1,@u2]
        end

        it "should add a team member" do
          p = { team_users_attributes: [
            { user_id: @u1.id }, { user_id: @u2.id }
          ] }
          put "/api/v1/projects/#{project.id}/teams/#{@team.id}", params: p
          response.should be_successful

          Team.last.users.to_a.should == [@u1,@u2]
        end

        it "should delete a team member" do
          @team.users << [@u1,@u2]
          @team.save!
          p = { team_users_attributes: [
            { id: @team.team_users.where(user_id:@u1.id).first.id, _destroy: 1 }
          ] }
          put "/api/v1/projects/#{project.id}/teams/#{@team.id}", params: p
          response.should be_successful
          Team.last.users.to_a.should == [@u2]
        end
      end

      context "edit a project team via nested routes" do
        it "should add a team member" do
          p = { user_id: @u1.id }
          post "/api/v1/projects/#{project.id}/teams/#{@team.id}/team_users", params: p
          response.should be_successful
          Team.last.users.to_a.should == [@u1]
        end

        it "should delete a team member" do
          @team.users << [@u1,@u2]
          @team.save!
          id = @team.team_users.where(user_id:@u1.id).first.id
          delete "/api/v1/projects/#{project.id}/teams/#{@team.id}/team_users/#{id}"
          response.should be_successful
          Team.last.users.to_a.should == [@u2]
        end
      end
    end
  end

  context "As a company admin" do
    before :all do
      @without_authentication = true
    end

    before :each do
      Grape::Endpoint.before_each do |endpoint|
        allow(endpoint).to receive(:current_user) do
          User.find_by_email("company.admin@springshot.com")
        end
      end
    end

    it "should return a list of all the company's projects" do
      get '/api/v1/projects', params: { offset: 0 }
      response.should be_successful
      json.length.should == 2
      json.map{|c| c['name']}.include?("Manufacture Sprockets").should == true
      json.map{|c| c['name']}.include?("Disassemble Sprockets").should == true
    end

  end

  context "As a project admin" do
    before :all do
      @without_authentication = true
    end
    before :each do
      Grape::Endpoint.before_each do |endpoint|
        allow(endpoint).to receive(:current_user) do
          User.find_by_email("project.admin@springshot.com")
        end
      end
    end

    it "should return a list of all the project admin's projects" do
      get '/api/v1/projects', params: { offset: 0 }
      response.should be_successful
      json.length.should == 1
      json.map{|c| c['name']}.include?("Manufacture Sprockets").should == true
      json.map{|c| c['name']}.include?("Disassemble Sprockets").should == false
    end
  end

  context :pagination do
    before(:all) do
      Project.destroy_all
      20.times { Project.make! }
    end

    it "should return the project API's declared default paginated results" do
      get '/api/v1/projects'
      response.should be_successful
      json.length.should == 2
      json.first['id'].should eq Project.all[2].id
      json.second['id'].should eq Project.all[3].id
      response.headers.slice("X-Total", "X-Total-Pages", "X-Per-Page", "X-Page", "X-Next-Page", "X-Prev-Page", "X-Offset").values.should eq ["20", "9", "2", "1", "2", "", "2"]
    end

    it "should return the request number of results" do
      get '/api/v1/projects', params: { per_page: 9, offset: 9 }
      response.should be_successful
      json.size.should == 9
      json.map {|j| j['id']}.should eq Project.all[9..17].map(&:id)
      response.headers.slice("X-Total", "X-Total-Pages", "X-Per-Page", "X-Page", "X-Next-Page", "X-Prev-Page", "X-Offset").values.should eq ["20", "2", "9", "1", "2", "", "9"]
    end

    it "should respect the maximum number of results" do
      get '/api/v1/projects', params: { per_page: 20, offset: 0 }
      response.code.should eq "400"
      json['error'].should eq "per_page must be less than or equal 10"
    end
  end


end
