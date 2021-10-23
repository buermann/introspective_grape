$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'introspective_grape/version'
# require 'introspective_grape/api'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'introspective_grape'
  s.version     = IntrospectiveGrape::VERSION
  s.authors     = ['Josh Buermann']
  s.email       = ['buermann@gmail.com']
  s.homepage    = 'https://github.com/buermann/introspective_grape'
  s.summary     = 'Introspectively configure deeply nested RESTful Grape APIs for ActiveRecord models.'
  s.description = 'Introspectively configure deeply nested RESTful Grape APIs for ActiveRecord models.'
  s.license     = 'MIT'

  s.files         = `git ls-files`.split('\n').sort
  s.test_files    = `git ls-files -- spec/*`.split('\n')

  s.required_ruby_version = '>= 2.5'

  s.add_runtime_dependency 'rails', '~> 5.2'
  s.add_runtime_dependency 'schema_validations'
  s.add_runtime_dependency 'rack'

  s.add_runtime_dependency 'grape'
  s.add_runtime_dependency 'dry-types'
  s.add_runtime_dependency 'grape-entity'
  s.add_runtime_dependency 'grape-swagger'

  s.add_runtime_dependency 'kaminari'
  s.add_runtime_dependency 'grape-kaminari'

  s.add_runtime_dependency 'pundit'

  s.add_runtime_dependency 'camel_snake_keys', '>0.0.4'

  if RUBY_PLATFORM == 'java'
    s.add_development_dependency 'activerecord-jdbcsqlite3-adapter'
  else
    s.add_development_dependency 'sqlite3'
  end

  # testing gems
  s.add_development_dependency 'rspec-rails', '>= 3.0'
  s.add_development_dependency 'coveralls_reborn'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'bundler-audit'
  s.add_development_dependency 'brakeman'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'machinist_redux'

  # dummy app dependencies
  s.add_development_dependency 'paperclip'
  s.add_development_dependency 'rufus-mnemo'
  s.add_development_dependency 'devise'
end
