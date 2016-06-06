class Dummy::UserAPI < IntrospectiveGrape::API

  skip_presence_validations :password

  include_actions User, :all
  exclude_actions Role, :show,:update
  exclude_actions UserProjectJob, :show,:update

  restful User, [:id, :email, :password, :first_name, :last_name, :skip_confirmation_email,
    user_project_jobs_attributes: [:id, :job_id, :project_id, :_destroy],
    roles_attributes: [:id, :ownable_type, :ownable_id, :_destroy],
    avatar_attributes: [:id, :file, :_destroy]
  ]

  class RoleEntity < Grape::Entity
    expose :id, :ownable_type, :ownable_id
  end

  class ImageEntity < Grape::Entity
    expose :id, :file_processing #, 'file.url'
  end

  class UserProjectJobEntity < Grape::Entity
    expose :id, :name, :title, :job_id, :project_id
  end

  class UserEntity < Grape::Entity
    expose :id, :email, :first_name, :last_name, :avatar_url, :created_at
    expose :roles, as: :roles_attributes, using: RoleEntity
    expose :user_project_jobs, as: :user_project_jobs_attributes, using: UserProjectJobEntity
  end 

end
