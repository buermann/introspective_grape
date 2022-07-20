require 'byebug'
require 'grape-kaminari'
class DummyAPI < Grape::API #::Instance
  include Grape::Kaminari

  version 'v1', using: :path
  format    :json
  formatter :json, IntrospectiveGrape::Formatter::CamelJson
  default_format :json


  include ErrorHandlers
  helpers PermissionsHelper
  helpers APIHelpers

  USER_NOT_CONFIRMED = 'user_not_confirmed'.freeze
  BAD_LOGIN          = 'bad_login'.freeze

  before do
    # sets server date in response header. This can be used on the client side
    header "X-Server-Date", Time.now.to_i.to_s
    header "Expires", 1.year.ago.httpdate
  end

  before_validation do
    Rails.logger.info "With params: #{params.to_hash.inspect}"
  end

  after do
    unless self.options[:path].first =~ /swagger/
      verify_authorized # Ensure that all endpoints are authorized by a policy class
    end
  end

  # Load the in-memory database for the test app
  load "#{Rails.root}/db/schema.rb"

  # Mount every api endpoint under app/api/dummy/.
  Dir.glob(Rails.root+"app"+"api"+'dummy'+'*.rb').each do |f|
    api = "Dummy::#{File.basename(f, '.rb').camelize.sub(/Api$/,'API')}"
    api = api.constantize
    mount api if api.respond_to? :endpoints
  end

  # configure grape-swagger to auto-generate swagger docs
  add_swagger_documentation({
    base_path:                "/api",
    doc_version:              'v1',
    hide_documentation_path:  true,
    format:                   :json,
    hide_format:              true,
    security_definitions: {
      api_key: {
        type: "apiKey",
        name: "api_key",
        in: "header"
      }
    }
  })

end
