require 'grape-swagger'
require 'active_support' #/core_ext/module/aliasing'
require 'camel_snake_keys'
if IntrospectiveGrape.config.camelize_parameters 
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
    module GrapeSwagger
      module DocMethods
        def self.extended(mod)
          # Do not camelize the grape-swagger documentation endpoints.
          mod.formatter :json, Grape::Formatter::Json
        end
        class ParseParams
          class << self
            def call_with_camelized(*args)
              param = call_without_camelized(*args)
              param[:name] = param[:name].camelize(:lower).gsub(/Destroy/, '_destroy')
              param
            end
            alias_method_chain :call, :camelized
          end
        end
      end
    end
  end
end
