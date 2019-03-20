require 'grape-swagger'
require 'active_support/core_ext/module/aliasing'
require 'active_support/inflector/methods'

if IntrospectiveGrape.config.camelize_parameters
  if Rails::gem_version >= Gem::Version.new('5.0.0')
    ### >= Rails 5.0 uses prepend instead of alias_method_chain

    module ParseParamsWithCamelized
      def parse_params(params, path, method, _options = {})
        parsed_params = parse_params_without_camelized(params, path, method)
        parsed_params.each_with_index do |param|
          param[:name] = param[:name]
            .camelize(:lower)
            .gsub(/Destroy/,'_destroy')
        end
        super(params, path, method, _options = {})
      end
    end

    module CreateCamelizedDocumentationClass
      private
      def create_documentation_class
        doc = create_documentation_class_without_camelized
        doc.class_eval do
          doc.singleton_class.send(:prepend, ParseParamsWithCamelized)
        end
        doc
      end
    end

    # Camelize the parameters in the swagger documentation.
    if Gem::Version.new( GrapeSwagger::VERSION ) <= Gem::Version.new('0.11.0')
      Grape::API.singleton_class.send(:prepend, CreateCamelizedDocumentationClass)
    else
      module CallWithCamelized
        def call(*args)
          param = super(*args)
          param[:name] = param[:name].camelize(:lower).gsub(/Destroy/, '_destroy')
          param
        end
      end

      GrapeSwagger::DocMethods::ParseParams.singleton_class.send(:prepend, CallWithCamelized)
      module GrapeSwagger
        module DocMethods
          def self.extended(mod)
            # Do not camelize the grape-swagger documentation endpoints.
            mod.formatter :json, Grape::Formatter::Json
          end
        end
      end
    end

  else
    ### < Rails 5.0 uses alias_method_chain

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
    else
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
end
