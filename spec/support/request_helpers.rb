require 'introspective_grape/utils/key_transformations'
require 'active_support/hash_with_indifferent_access'
module RequestHelpers

  def json
    @json ||= begin
      parsed_response_body = JSON.parse(response.body)
      case parsed_response_body
      when Array then parsed_response_body.map { |x| snake_keys_with_indifferent_access(x) }
      when Hash then snake_keys_with_indifferent_access(parsed_response_body)
      else parsed_response_body
      end
    end
  end

  def snake_keys_with_indifferent_access(hash)
    ActiveSupport::HashWithIndifferentAccess.new(
      IntrospectiveGrape::Utils::KeyTransformations.snake_keys(
        hash
      )
    )
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


