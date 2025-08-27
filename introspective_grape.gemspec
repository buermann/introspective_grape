$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'introspective_grape/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'introspective_grape'
  s.version     = IntrospectiveGrape::VERSION
  s.authors     = ['Josh Buermann']
  s.email       = ['buermann@gmail.com']
  s.homepage    = 'https://github.com/buermann/introspective_grape'
  s.summary     = 'Quickly configure Grape APIs around your database schema and models.'
  s.description = <<-DESC
    IntrospectiveGrape provides handling for deeply nested relations according to the models'
    `accepts_nested_attributes_for` declarations, generating all the necessary
    boilerplate for flexible and consistent bulk endpoints on plural associations,
    and building nested routes for the same.
  DESC
  s.license     = 'MIT'
  s.metadata    = { 'rubygems_mfa_required' => 'true' }

  s.files         = `git ls-files`.split("\n").sort

  s.required_ruby_version = '>= 3.1'

  s.add_dependency 'rails' # , '6.1' #, '> 5.2'
  s.add_dependency 'rack'

  s.add_dependency 'grape' # , '1.6.0'
  s.add_dependency 'dry-types'
  s.add_dependency 'grape-entity'
  s.add_dependency 'grape-swagger'

  s.add_dependency 'kaminari'
  s.add_dependency 'grape-kaminari'

  s.add_dependency 'pundit'

  s.add_dependency 'camel_snake_keys'
end
