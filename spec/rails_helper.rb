ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../dummy/config/environment", __FILE__)
require 'rspec/rails'
require 'support/request_helpers'
require 'support/pundit_helpers'
Dir[Rails.root.join("../support/**/*.rb")].each { |f| require f }

#load "#{Rails.root}/db/schema.rb"
RSpec.configure do |config|
  config.include Devise::TestHelpers, type: :controller
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.expect_with(:rspec) { |c| c.syntax = :should }

  # load helpers for the API tests
  config.include RequestHelpers, type: :request
  config.before(:each, type: :request) do
    # run all requests as super user, test permissions under policies
    with_authentication
  end

end

