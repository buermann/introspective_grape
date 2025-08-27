source 'https://rubygems.org'
gemspec

gem 'devise'
gem 'grape-entity'
gem 'grape-swagger'
gem 'validates_by_schema'

# Declare your gem's dependencies in introspective_grape.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.


# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.


group :development, :test do
  # testing
  gem 'brakeman'
  gem 'bundler-audit'
  gem 'byebug'
  gem 'coveralls_reborn', require: false
  gem 'machinist_redux'
  gem 'rb-readline'
  gem 'rspec-rails', '>= 3.0'
  gem 'rubocop'
  gem 'simplecov'

  # dummy app dependencies
  gem 'activerecord-jdbcsqlite3-adapter', platforms: :jruby
  gem 'devise'
  gem 'kt-paperclip'
  gem 'rufus-mnemo'
  gem 'sqlite3', platforms: :ruby
end
