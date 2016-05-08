require 'grape-swagger'
require 'active_support' #/core_ext/module/aliasing'
require 'camel_snake_keys'

if IntrospectiveGrape.config.camelize_parameters 
  # Monkey patch Grape's built in JSON formatter to convert all snake case hash keys
  # from ruby to camel case.
  Grape::Formatter::Json::class_eval do 
    def call(object, _env)
      if object.respond_to?(:to_json)
        JSON.parse(object.to_json).with_camel_keys.to_json
      else
        MultiJson.dump(object).with_camel_keys.to_json
      end
    end
  end

  # Camelize the parameters in the swagger documentation.
  if Gem::Version.new( GrapeSwagger::VERSION ) <= Gem::Version.new('0.11.0')
    Grape::API.class_eval do 
      class << self
        private
        def create_documentation_class_with_camelized
          doc = create_documentation_class_without_camelized
          doc.class_eval do
            class << self
              def parse_params_with_camelized(params, path, method, _options = {})
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
  else Gem::Version.new( GrapeSwagger::VERSION ) > Gem::Version.new('0.11.0')
    # Grape::Swagger 0.20.xx is not yet compatible with Grape >0.14 and will alter
    # the way it parses params, so will not be compatible with introspective_grape,
    # and produces swagger docs for SwaggerUI 2.1.4 that don't appear to be
    # backwards compatible swagger.js 2.0.41, so this is pending.
  end

end
