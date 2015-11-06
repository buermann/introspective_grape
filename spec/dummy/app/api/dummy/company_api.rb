class Dummy::CompanyAPI < IntrospectiveGrape::API
  restful Company

  class CompanyEntity < Grape::Entity
    expose :id, :name, :short_name, :created_at, :updated_at
  end
end

