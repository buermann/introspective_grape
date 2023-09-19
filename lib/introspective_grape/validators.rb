require 'grape/validations'
module Grape
  module Validators
    # Validations::Base becomes Validators::Base somewhere between 1.6.0 and 1.6.2
    validation_class = defined?(Grape::Validations::Validators::Base) ? Grape::Validations::Validators::Base : Grape::Validations::Base

    class Json < validation_class
      def validate_param!(field, params)
        begin
          JSON.parse( params[field] )
        rescue StandardError
          raise Grape::Exceptions::Validation.new params: [@scope.full_name(field)], message: 'must be valid JSON!'
        end
      end
    end

    class JsonArray < validation_class
      def validate_param!(field, params)
        begin
          raise unless JSON.parse( params[field] ).is_a? Array
        rescue StandardError
          raise Grape::Exceptions::Validation.new params: [@scope.full_name(field)], message: 'must be a valid JSON array!'
        end
      end
    end

    class JsonHash < validation_class
      def validate_param!(field, params)
        begin
          raise unless JSON.parse( params[field] ).is_a? Hash
        rescue StandardError
          raise Grape::Exceptions::Validation.new params: [@scope.full_name(field)], message: 'must be a valid JSON hash!'
        end
      end
    end
  end
end
