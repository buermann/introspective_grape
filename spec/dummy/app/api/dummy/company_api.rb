class Dummy::CompanyAPI < IntrospectiveGrape::API
  paginate

  restful Company, [:id, :name, :short_name, :gizmos, :widgets, :sprockets] do

    desc "Test default values in an extra endpoint"
    params do
      optional :boolean_default, type: Virtus::Attribute::Boolean, default: false
      optional :string_default, type: String, default: "foo"
      optional :integer_default, type: Integer, default: 123
    end
    get '/special/list' do
      authorize Company.new, :index?
      present params
    end

  end

  class CompanyEntity < Grape::Entity
    expose :id, :name, :short_name, :created_at, :updated_at
  end
end

