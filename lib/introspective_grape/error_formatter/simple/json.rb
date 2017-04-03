require_relative 'base'
module IntrospectiveGrape
  module ErrorFormatter
    module Simple

      # Returns consistent error messages for a JSON api.
      # In order to enable, make sure it comes before calls for #format :json.
      #
      # Inspired by stack overflow response: https://goo.gl/0jzqtv.
      #
      # For example:
      #
      # class ApplicationApi < Grape::API
      #
      #  Grape::ErrorFormatter.register(:json, IntrospectiveGrape::ErrorFormatter::Simple::Json)
      #  format :json
      # end
      #
      module Json
        extend IntrospectiveGrape::ErrorFormatter::Simple::Base

        class << self

          def call(message, backtrace, options = {}, env = nil)
            MultiJson.dump(format(message, backtrace, options, env))
          end
        end

      end
    end
  end
end
