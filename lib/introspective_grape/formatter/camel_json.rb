# Add a formatter to grape that converts all snake case hash keys from ruby to camel case.
require 'camel_snake_keys'
module IntrospectiveGrape
  module Formatter
    module CamelJson
      def self.call(object, _env)
        if object.respond_to?(:to_json)
          JSON.parse(object.to_json).with_camel_keys.to_json
        else
          MultiJson.dump(object).with_camel_keys.to_json
        end
      end
    end
  end
end
