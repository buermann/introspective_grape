require 'introspective_grape/camel_snake'
module RequestHelpers

  def json
    @json ||= CamelSnakeKeys.snake_keys(JSON.parse(response.body), true)
  end

  def with_authentication(role=:superuser)
    return if @without_authentication
    current_user = User.find_or_create_by(email: 'test@test.com', superuser: true, authentication_token: '1234567890', first_name: "First", last_name: "Last")
    Current.user = current_user
    allow(current_user).to receive(:admin?)     { true } if role == :superuser
    allow(current_user).to receive(:superuser?) { true } if role == :superuser

    # Stubbing API helper methods requires this very nearly undocumented invokation
    Grape::Endpoint.before_each do |endpoint|
      allow(endpoint).to receive(:current_user) { current_user }
    end
  end
end


