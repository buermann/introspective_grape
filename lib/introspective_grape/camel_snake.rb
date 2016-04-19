require 'grape-swagger'
require 'active_support' #/core_ext/module/aliasing'
module IntrospectiveGrape::CamelSnake
  def snake_keys(data)
    if data.kind_of? Array
      data.map { |v| snake_keys(v) }
    elsif data.kind_of? HashWithIndifferentAccess
      HashWithIndifferentAccess[data.map {|k, v| [k.to_s.underscore, snake_keys(v)] }]
    elsif data.kind_of? Hash
      Hash[data.map {|k, v| [k.to_s.underscore, snake_keys(v)] }]
    else
      data
    end
  end

  def camel_keys(data)
    if data.kind_of? Array
      data.map { |v| camel_keys(v) }
    elsif data.kind_of?(HashWithIndifferentAccess)
      HashWithIndifferentAccess[data.map {|k, v| [k.to_s.camelize(:lower), camel_keys(v)] }]
    elsif data.kind_of?(Hash)
      Hash[data.map {|k, v| [k.to_s.camelize(:lower), camel_keys(v)] }]
    else
      data
    end
  end
end

# Monkey patch Grape's built in JSON formatter to convert all snake case hash keys
# to camel case.
module Grape
  module Formatter
    module Json
      class << self
        include IntrospectiveGrape::CamelSnake
        def call(object, env)
          if object.respond_to?(:to_json)
            camel_keys(JSON.parse(object.to_json)).to_json
         else
            camel_keys(MultiJson.dump(object)).to_json
          end
        end
      end
    end
  end
end

# Camelize the parameters in the swagger documentation.
if Gem::Version.new( GrapeSwagger::VERSION ) <= Gem::Version.new('0.11.0')
  module Grape
    class API
      class << self
        private
        def create_documentation_class_with_camelized
          doc = create_documentation_class_without_camelized
          doc.class_eval do
            class << self
              def parse_params_with_camelized(params, path, method, options = {})
                parsed_params = parse_params_without_camelized(params, path, method)
                parsed_params.each_with_index do |param|
                  param[:name] = param[:name]
                  .camelize(:lower)
                  .gsub(/Destroy/,'_destroy')
                end
                parsed_params
              end

              alias_method_chain :parse_params, :camelized
            end
          end
          doc
        end
        alias_method_chain :create_documentation_class, :camelized
      end
    end
  end
else Gem::Version.new( GrapeSwagger::VERSION ) > Gem::Version.new('0.11.0')
  # Grape::Swagger 0.20.xx is not yet compatible with Grape >0.14 and will alter
  # the way it parses params, so will not be compatible with introspective_grape,
  # and produces swagger docs for SwaggerUI 2.1.4 that don't appear to be
  # backwards compatible swagger.js 2.0.41, so this is pending.
end
