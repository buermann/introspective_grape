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
        _deep_transform_keys_in_object(data) { |key| camelize(key) }
      end

      # Converts all the keys to snakecase.
      def snake_keys(data)
        _deep_transform_keys_in_object(data) { |key| snakeize(key) }
      end

      private

      # Copied from 'active_support/core_ext/hash/keys' ( > 4.1.8) so that a) we don't have to extend Hash and b)
      # to be able to access the function directly instead of needing to do
      # {}.send(:_deep_transform_keys_in_object, data)
      #
      # support methods for deep transforming nested hashes and arrays
      def _deep_transform_keys_in_object(object, &block)
        case object
        when Hash
          object.each_with_object({}) do |(key, value), result|
            result[yield(key)] = _deep_transform_keys_in_object(value, &block)
          end
        when Array
          object.map {|e| _deep_transform_keys_in_object(e, &block) }
        else
          object
        end
      end

    end
  end
end