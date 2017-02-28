# Add a formatter to grape that converts all snake case hash keys from ruby to camel case.
require 'camel_snake_keys'
require 'grape/formatter/json'
module IntrospectiveGrape
  module Formatter
    module CamelJson
      def self.call(object, _env)
        if object.respond_to?(:to_json) && !object.respond_to?(:with_camel_keys) &&
          (parsed_object = JSON.parse(object.to_json)).respond_to?(:with_camel_keys)
          object = parsed_object
				elsif object.kind_of?(Array) && object.first.kind_of?(Grape::Entity)
        	# Force arrays of Grape::Entities into their hash representations before camelizing
        	object = JSON.parse(object.to_json) 
        end
        object = object.with_camel_keys if object.respond_to?(:with_camel_keys)

        Grape::Formatter::Json.call(object, _env)
      end
    end
  end
end
