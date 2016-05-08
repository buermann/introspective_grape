require 'rails_helper'

RSpec.describe UserProjectJob, type: :model do

  it "should delegate user name" do
    UserProjectJob.make.name.should_not == nil
  end

  it "should delegate user email" do
    UserProjectJob.make.email.should_not == nil
  end

  it "should delegate job title" do
    UserProjectJob.make.title.should_not == nil
  end

  it "should scope job options by project" do 
    ProjectJob.make!
    ProjectJob.make!

    p = Project.make!
    j = Job.make!
    p.jobs.push j
    p.save
    UserProjectJob.make!(project: p, job: j) 
    UserProjectJob.options_for_job(p).should == p.jobs
  end


end
