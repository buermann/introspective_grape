# Add a formatter to grape that converts all snake case hash keys from ruby to camel case.
require 'camel_snake_keys'
require 'grape/formatter/json'
module IntrospectiveGrape
  module Formatter
    module CamelJson
      class << self
        def transform_to_camel_keys(object)
          # We only need to parse(object.to_json) like this if it isn't already
          # a native hash (or array of them), i.e. we have to parse Grape::Entities
          # and other formatter facades:
          has_hash = (object.is_a?(Array) && object.first.is_a?(Hash)) || object.is_a?(Hash)
          object   = JSON.parse(object.to_json) if object.respond_to?(:to_json) && !has_hash
          CamelSnakeKeys.camel_keys(object)
        end

        def call(object, env)
          Grape::Formatter::Json.call(transform_to_camel_keys(object), env)
        end
      end
    end
  end
end
