require 'rails_helper'

RSpec.describe Role, type: :model do
  before :all do
  end
  let(:user) { User.make! }
  let(:company) { Company.make! }
  let(:project) { Project.make! }

  it "allows user assignment to company admin" do
    ur = Role.create(user:user, ownable: company)
    ur.valid?.should be_truthy
  end

  it "invalidates a user role with an invalid ownable like 'Role'" do
    ur = Role.create(user:user, ownable: Role.new)
    ur.valid?.should be_falsey
  end

  context "User helper methods" do
    it "should register a user as a super user" do
      user.superuser?.should == false
      user.superuser = true
      user.superuser?.should == true
    end

    it "should register a company admin" do
      user.admin?(company).should == false
      Role.create!(user:user, ownable: company)
      user.reload
      user.admin?(company).should == true
    end

    it "should register a project administrator" do
      user.admin?(project).should == false
      Role.create!(user:user, ownable: project)
      user.reload
      user.admin?(project).should == true
    end

    it "should register a user a company admin if admin of any company" do
      user.company_admin?.should == false
      Role.create!(user:user, ownable: company)
      user.reload
      user.company_admin?.should == true
    end

    it "should register a user as a project admin if admin of any project" do
      user.project_admin?.should == false
      Role.create!(user:user, ownable: project)
      user.reload
      user.project_admin?.should == true
    end

  end

end
