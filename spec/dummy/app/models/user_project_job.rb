class UserProjectJob < AbstractAdapter
  belongs_to :user,    inverse_of: :user_project_jobs
  belongs_to :project, inverse_of: :user_project_jobs
  belongs_to :job,     inverse_of: :user_project_jobs

  validates_inclusion_of :job, in: proc {|r| r.project.try(:jobs) || [] }

  delegate :email, :avatar_url, to: :user,    allow_nil: true
  delegate :title,              to: :job,     allow_nil: true
  delegate :name,               to: :project, allow_nil: true

  def self.options_for_job(project=nil)
    project.jobs
  end

end
