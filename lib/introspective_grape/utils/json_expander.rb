module IntrospectiveGrape
  module Utils
    module JsonExpander
      extend self

      # Expands an object with its #to_json method if it's not a primitive or if the first element is a Grape::Entity.
      def expand(object)
        if (object.respond_to?(:to_json) &&
          [String, Symbol, Hash, Array, NilClass, TrueClass, FalseClass, Numeric].all? { |x| !object.is_a?(x) }) ||
          # Force arrays of Grape::Entities into their hash representations before camelizing
          (object.is_a?(Array) && defined?(Grape::Entity) && object.first.is_a?(Grape::Entity))

          JSON.parse(object.to_json)
        else
          object
        end
      end

    end
  end
end