class Dummy::ProjectAPI < IntrospectiveGrape::API

  default_includes Project, :owner, :admins, :user_project_jobs, project_jobs: [:job], teams: [:team_users]
  default_includes Team, :team_users
  default_includes TeamUser, user: [:projects], team: [:project]
  default_includes ProjectJob, :job

  exclude_actions Project, :create,:destroy,:update
  exclude_actions Team, :show
  exclude_actions TeamUser, :show,:update

  paginate per_page: 2, max_per_page: 10, offset: 2

  restful Project, [:id, teams_attributes: [:id,:name,:_destroy, team_users_attributes: [:id, :user_id, :_destroy] ]]

  class AdminEntity < Grape::Entity
    expose :id, as: :user_id
    expose :email, :name, :avatar_url
  end

  class UserJobEntity < Grape::Entity
    expose :user_id, :name, :email, :avatar_url, :title, :created_at
  end

  class JobEntity < Grape::Entity
    expose :title
  end

  class UserEntity < Grape::Entity
    expose :id, :name, :avatar_url
  end

  class TeamUserEntity < Grape::Entity
    expose :id
    expose :user, using: UserEntity
  end

  class TeamEntity < Grape::Entity
    expose :id, :name, :created_at, :updated_at
    expose :team_users, using: TeamUserEntity
  end

  class ProjectEntity < Grape::Entity
    expose :id, :name, :created_at, :updated_at
    expose :owner,  using: Dummy::CompanyAPI::CompanyEntity
    expose :admins, using: AdminEntity
    expose :project_jobs,      as: :jobs,      using: JobEntity
    expose :user_project_jobs, as: :user_jobs, using: UserJobEntity
    expose :teams, using: TeamEntity
  end
end

