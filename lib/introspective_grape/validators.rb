require 'grape/validations'
module Grape
  module Validators
    class Json < Grape::Validations::Base
      def validate_param!(field, params)
        begin
          JSON.parse( params[field] )
        rescue StandardError
          raise Grape::Exceptions::Validation, params: [@scope.full_name(field)], message: 'must be valid JSON!'
        end
      end
    end

    class JsonArray < Grape::Validations::Base
      def validate_param!(field, params)
        begin
          raise unless JSON.parse( params[field] ).is_a? Array
        rescue StandardError
          raise Grape::Exceptions::Validation, params: [@scope.full_name(field)], message: 'must be a valid JSON array!'
        end
      end
    end

    class JsonHash < Grape::Validations::Base
      def validate_param!(field, params)
        begin
          raise unless JSON.parse( params[field] ).is_a? Hash
        rescue StandardError
          raise Grape::Exceptions::Validation, params: [@scope.full_name(field)], message: 'must be a valid JSON hash!'
        end
      end
    end
  end
end
