# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!
#load "#{Rails.root}/db/schema.rb"


#Dir[Rails.root.join("app/api/**/*.rb")].each { |f| require f }
Rails.application.reload_routes!

