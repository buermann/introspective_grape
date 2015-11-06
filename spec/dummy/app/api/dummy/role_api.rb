class Dummy::RoleAPI < IntrospectiveGrape::API
  restful Role

  class RoleEntity < Grape::Entity
    expose :id, :email, :ownable_type, :ownable_id, :created_at, :updated_at
  end
end
