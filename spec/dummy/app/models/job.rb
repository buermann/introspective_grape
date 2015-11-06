class Job < AbstractAdapter

  has_many :project_jobs,     dependent: :destroy
  accepts_nested_attributes_for :project_jobs, allow_destroy: true

  has_many :user_project_jobs, dependent: :destroy
  has_many :users,    through: :user_project_jobs
  has_many :projects, through: :user_project_jobs

end
