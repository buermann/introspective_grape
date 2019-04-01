$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "introspective_grape/version"
#require "introspective_grape/api"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "introspective_grape"
  s.version     = IntrospectiveGrape::VERSION
  s.authors     = ["Josh Buermann"]
  s.email       = ["buermann@gmail.com"]
  s.homepage    = "https://github.com/buermann/introspective_grape"
  s.summary     = "Introspectively configure deeply nested RESTful Grape APIs for ActiveRecord models."
  s.description = "Introspectively configure deeply nested RESTful Grape APIs for ActiveRecord models."
  s.license     = "MIT"

  s.files         = `git ls-files`.split("\n").sort
  s.test_files    = `git ls-files -- spec/*`.split("\n")

  s.required_ruby_version = '>= 2.3'

  s.add_dependency "rails", '> 5.0.0'

  # grape 1.0.0 breaks the pagination solution
  s.add_dependency 'grape', '~> 1.2.0'
  s.add_dependency 'grape-entity'
  s.add_dependency 'grape-swagger'
  s.add_dependency 'kaminari' #, '< 1.0' # version 1.0.0 breaks
  #s.add_dependency 'grape-kaminari', :github => 'alexey-klimuk/grape-kaminari'
  # Pundit 2.0 mysteriously made authorize a protected method...
  s.add_dependency 'pundit' #, '<2.0'
  s.add_dependency 'camel_snake_keys', '>0.0.4'

  if RUBY_PLATFORM == 'java'
    #s.add_development_dependency "jdbc-sqlite3"
    s.add_development_dependency "activerecord-jdbcsqlite3-adapter"
  else
    s.add_development_dependency "sqlite3", '<1.4.0' #'< 1.3.14'
  end

  #s.add_development_dependency "byebug"
  #s.add_development_dependency "rb-readline"
  s.add_development_dependency "rspec-rails", '>= 3.0'
  s.add_development_dependency 'devise'
  #s.add_development_dependency 'devise-async'
  s.add_development_dependency 'paperclip', ">= 5.2.0" #'< 5.0'
  s.add_development_dependency 'machinist_redux'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rufus-mnemo'

end
