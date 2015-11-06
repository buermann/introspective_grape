class TeamUser < AbstractAdapter
  belongs_to :user
  belongs_to :team

  validate :user_on_project

  def user_on_project
    unless user && team && user.projects.include?(team.project)
      errors.add(:user, "#{user.try(:name)} is not on the #{team.try(:project).try(:name)} project")
    end
  end

end
