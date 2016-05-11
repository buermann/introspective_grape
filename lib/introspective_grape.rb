module IntrospectiveGrape
  autoload :API,        'introspective_grape/api'
  autoload :Helpers,  'introspective_grape/helpers'
  autoload :CamelSnake, 'introspective_grape/camel_snake'
  autoload :Formatter, 'introspective_grape/formatter/camel_json'

  def self.config
    @config = OpenStruct.new(camelize_parameters: true)
  end
end
