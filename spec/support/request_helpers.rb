require 'introspective_grape/camel_snake'
module RequestHelpers
  include IntrospectiveGrape::CamelSnake 

  def json
    @json ||= snake_keys(JSON.parse(response.body))
  end

  def with_authentication(role=:superuser)
    return if @without_authentication
    current_user = User.new #double('User')
    allow(current_user).to receive(:admin?) { true }     if role == :superuser 
    allow(current_user).to receive(:superuser?) { true } if role == :superuser

    # Stubbing API helper methods requires this very nearly undocumented invokation
    Grape::Endpoint.before_each do |endpoint|
      allow(endpoint).to receive(:current_user) { current_user } 
    end
  end
end


