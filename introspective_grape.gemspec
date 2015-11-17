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
  s.homepage    = "TODO"
  s.summary     = "Introspectively configure deeply nested RESTful Grape APIs for ActiveRecord models."
  s.description = ""
  s.license     = "MIT"

  s.files         = `git ls-files`.split("\n").sort
  s.test_files    = `git ls-files -- spec/*`.split("\n")

  s.required_ruby_version = '~> 2.0'

  s.add_dependency "rails"
  s.add_dependency "activerecord"

  s.add_dependency 'grape'
  s.add_dependency 'grape-entity'
  s.add_dependency 'grape-swagger'
  s.add_dependency 'pundit'

  if RUBY_PLATFORM == 'java'
    s.add_development_dependency "jdbc-sqlite3"
  else
    s.add_development_dependency "sqlite3"
  end

  s.add_development_dependency "rspec-rails", '>= 3.0'
  s.add_development_dependency 'devise'
  s.add_development_dependency 'devise-async'
  s.add_development_dependency 'paperclip'
  s.add_development_dependency 'machinist'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rufus-mnemo'
  #s.add_development_dependency "schema_plus", "2.0.0.pre12" # For compatibility of schema_validations with AR 4.2.1+
  #s.add_development_dependency "schema_validations"
  s.add_development_dependency "activerecord-tableless", "~> 1.0"

end
