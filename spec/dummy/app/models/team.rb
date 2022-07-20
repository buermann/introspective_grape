class Team < AbstractAdapter
  belongs_to :project
  belongs_to :creator, class_name: 'User'

  has_many :team_users, inverse_of: :team
  has_many :users, through: :team_users
  accepts_nested_attributes_for :team_users, allow_destroy: true

  before_validation :set_creator

  def set_creator
    self.creator ||= Current.user
  end
end
