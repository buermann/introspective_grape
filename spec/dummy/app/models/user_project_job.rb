class UserProjectJob < AbstractAdapter
  belongs_to :user,    inverse_of: :user_project_jobs
  belongs_to :project, inverse_of: :user_project_jobs
  belongs_to :job,     inverse_of: :user_project_jobs

  validates_inclusion_of :job, in: proc {|r| r.project.try(:jobs) || [] }

  delegate :email, :avatar_url, to: :user
  delegate :title, to: :job
  delegate :name,  to: :project

  def self.options_for_job(project=nil)
    project.jobs
  end

end
