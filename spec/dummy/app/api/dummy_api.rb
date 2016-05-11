#require 'grape-swagger'
#require 'grape-entity'
#require 'introspective_grape/camel_snake'

class DummyAPI < Grape::API
  version 'v1', using: :path
  format    :json
  formatter :json, IntrospectiveGrape::Formatter::CamelJson
  default_format :json

  include ErrorHandlers
  helpers PermissionsHelper
  helpers ApiHelpers

  USER_NOT_CONFIRMED = 'user_not_confirmed'.freeze
  BAD_LOGIN          = 'bad_login'.freeze

  before do
    # sets server date in response header. This can be used on the client side
    header "X-Server-Date", Time.now.to_i.to_s
    header "Expires", 1.year.ago.httpdate
    # Convert incoming camel case params to snake case: grape will totally blow this
    # if the params hash is not a Hashie::Mash, so make it one of those:
    #@params = Hashie::Mash.new(params.with_snake_keys)
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
    api = "Dummy::#{File.basename(f, '.rb').camelize.sub(/Api$/,'API')}".constantize
    mount api if api.respond_to? :endpoints
  end

  # configure grape-swagger to auto-generate swagger docs
  protocol = Rails.application.config.force_ssl ? 'https' : 'http'
  add_swagger_documentation({
    base_path:                "#{protocol}://localhost:3000/api",
    api_version:              'v1',
      hide_documentation_path:  true,
      format:                   :json,
      hide_format:              true
     #markdown:                 true
  })

end
