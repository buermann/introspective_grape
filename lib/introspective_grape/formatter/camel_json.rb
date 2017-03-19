require 'grape/formatter/json'
require_relative '../utils/key_transformations'
require_relative '../utils/json_expander'

module IntrospectiveGrape
  module Formatter
    module CamelJson
      def self.call(object, _env)
        object = IntrospectiveGrape::Utils::JsonExpander.expand(object)
        object = IntrospectiveGrape::Utils::KeyTransformations.camel_keys(object)
        Grape::Formatter::Json.call(object, _env)
      end
    end
  end
end
