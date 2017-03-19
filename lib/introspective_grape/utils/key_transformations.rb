require 'active_support/core_ext/hash/keys' # for _deep_transform_keys_in_object
require 'active_support/inflector/methods'
module IntrospectiveGrape
  module Utils
    module KeyTransformations
      extend self

      def camelize(key)
        (key.is_a?(String) || key.is_a?(Symbol)) ? ActiveSupport::Inflector.camelize(key.to_s, false) : key
      end

      def snakeize(key)
        (key.is_a?(String) || key.is_a?(Symbol)) ? ActiveSupport::Inflector.underscore(key.to_s) : key
      end

      # Converts all the keys to camelcase with lowercase first letter.
      def camel_keys(data)
        {}.send(:_deep_transform_keys_in_object, data) { |key| camelize(key) }
      end

      # Converts all the keys to snakecase.
      def snake_keys(data)
        {}.send(:_deep_transform_keys_in_object, data) { |key| snakeize(key) }
      end

    end
  end
end