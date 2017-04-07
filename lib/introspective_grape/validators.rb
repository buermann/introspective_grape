require 'grape/validations'
module Grape::Validators

  class Json < Grape::Validations::Base
    def validate_param!(field, params)
      begin
        JSON.parse( params[field] )
      rescue
        fail Grape::Exceptions::Validation, params: [@scope.full_name(field)], message: 'must be valid JSON!'
      end
    end
  end

  class JsonArray < Grape::Validations::Base
    def validate_param!(field, params)
      begin
        raise unless JSON.parse( params[field] ).kind_of? Array
      rescue
        fail Grape::Exceptions::Validation, params: [@scope.full_name(field)], message: 'must be a valid JSON array!'
      end
    end
  end

  class JsonHash < Grape::Validations::Base
    def validate_param!(field, params)
      begin
        raise unless JSON.parse( params[field] ).kind_of? Hash
      rescue
        fail Grape::Exceptions::Validation, params: [@scope.full_name(field)], message: 'must be a valid JSON hash!'
      end
    end
  end

end
