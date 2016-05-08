module IntrospectiveGrape
  autoload :API,        'introspective_grape/api'
  autoload :Helpers,  'introspective_grape/helpers'
  autoload :CamelSnake, 'introspective_grape/camel_snake'

  def self.config
    @config = OpenStruct.new(camelize_parameters: true)
  end
end
