module IntrospectiveGrape
  autoload :API,            'introspective_grape/api'
  autoload :CamelSnake,     'introspective_grape/camel_snake'
  autoload :CreateHelpers,  'introspective_grape/create_helpers'
  autoload :Doc,            'introspective_grape/doc'
  autoload :Filters,        'introspective_grape/filters'
  autoload :Helpers,        'introspective_grape/helpers'
  autoload :SnakeParams,    'introspective_grape/snake_params'
  autoload :Traversal,      'introspective_grape/traversal'

  module Formatter
    autoload :CamelJson, 'introspective_grape/formatter/camel_json'
  end

  module Utils
    autoload :KeyTransformations, 'introspective_grape/utils/key_transformations'
    autoload :JsonExpander,       'introspective_grape/utils/json_expander'
  end

  def self.config
    @config = OpenStruct.new(camelize_parameters: true)
  end
end
