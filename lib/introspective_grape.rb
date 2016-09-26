module IntrospectiveGrape
  autoload :API,        'introspective_grape/api'
  autoload :CamelSnake, 'introspective_grape/camel_snake'
  autoload :Filters,    'introspective_grape/filters'
  autoload :Helpers,    'introspective_grape/helpers'
  autoload :Traversal,  'introspective_grape/traversal'

  module Formatter
    autoload :CamelJson, 'introspective_grape/formatter/camel_json'
  end

  def self.config
    @config = OpenStruct.new(camelize_parameters: true)
  end
end
