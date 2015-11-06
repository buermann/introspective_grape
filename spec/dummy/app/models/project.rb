class Project < AbstractAdapter
  belongs_to :owner, foreign_key: :owner_id, class_name: 'Company'

  has_many :roles, as: :ownable
  has_many :admins, through: :roles, source: :user
  accepts_nested_attributes_for :roles, allow_destroy: true

  has_many :project_jobs,  dependent: :destroy, inverse_of: :project
  has_many :jobs,     through: :project_jobs
  accepts_nested_attributes_for :project_jobs, allow_destroy: true
  
  has_many :user_project_jobs, dependent: :destroy, inverse_of: :project
  has_many :users,    through: :user_project_jobs, inverse_of: :projects
  accepts_nested_attributes_for :user_project_jobs, allow_destroy: true

  has_many :teams, dependent: :destroy, inverse_of: :project
  accepts_nested_attributes_for :teams, allow_destroy: true


end
