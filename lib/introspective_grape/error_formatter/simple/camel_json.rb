require_relative 'base'
require_relative '../../utils/key_transformations'
# require_relative '../../utils/json_expander'
module IntrospectiveGrape
  module ErrorFormatter
    module Simple
      module CamelJson
        extend IntrospectiveGrape::ErrorFormatter::Simple::Base

        class << self

          def call(message, backtrace, options = {}, env = nil)
            MultiJson.dump(camelize_keys(format(message, backtrace, options, env)))
          end

          private

          def camelize_keys(object)
            # object = IntrospectiveGrape::Utils::JsonExpander.expand(object)
            IntrospectiveGrape::Utils::KeyTransformations.camel_keys(object)
          end

        end
      end
    end
  end
end