require 'grape/error_formatter/base'
module IntrospectiveGrape
  module ErrorFormatter
    module Simple
      module Base
        include Grape::ErrorFormatter::Base

        def self.extended(base)
          class << base
            attr_accessor :default_message_key
          end
          base.default_message_key = "general"
        end

        private

        def format(message, backtrace, options = {}, env = nil)
          result = wrap_message(present(message, env))

          if (options[:rescue_options] || {})[:backtrace] && backtrace && !backtrace.empty? &&
            result[:errors] && result[:errors][default_message_key]

            result[:errors][default_message_key].concat(backtrace)
          end

          result
        end

        # Follows a consistent API interface that works for returning errors in a Restful API, when there are one
        # or many errors (say for validation errors).
        #
        # Looks something like this:
        #
        #  "errors" => {
        #     "general" => [
        #        "error message when there is only one error"
        #      ],
        #     # And when you need to include more errors...
        #     "first_name" => [
        #        "is too short",
        #        "includes invalid characters"
        #      ],
        #     "telephone" => [
        #        "is not provided"
        #      ]
        #   }
        #
        #
        def wrap_message(message)
          if message.is_a?(Grape::Exceptions::ValidationErrors)
            message = message.errors.inject({}) do |hash, (k, v)|
              hash[k[0]] = v
              hash
            end
          end
          errors = if message.is_a?(Hash)
            message
          else
            {default_message_key => (message.is_a?(Array) ? message : [message])}
          end
          { errors: errors }
        end

      end

    end
  end
end
