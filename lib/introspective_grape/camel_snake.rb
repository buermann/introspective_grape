require 'grape-swagger'
require 'active_support/core_ext/module/aliasing'
require 'active_support/inflector/methods'

if IntrospectiveGrape.config.camelize_parameters
  # Camelize the parameters in the swagger documentation.
  if Gem::Version.new( GrapeSwagger::VERSION ) <= Gem::Version.new('0.11.0')
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
        doc = super
        doc.class_eval do
          doc.singleton_class.send(:prepend, ParseParamsWithCamelized)
        end
        doc
      end
    end

    Grape::API::Instance.singleton_class.send(:prepend, CreateCamelizedDocumentationClass)
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

end
