module IntrospectiveGrape
  module SnakeParams

    def snake_params_before_validation
      before_validation do
        # We have to snake case the Rack params then re-assign @params to the
        # request.params, because of the I-think-very-goofy-and-inexplicable
        # way Grape interacts with both independently of each other
        (CamelSnakeKeys.snake_keys(params)||{}).each do |k,v|
          request.delete_param(k.camelize(:lower))
          request.update_param(k, v)
        end
        @params = request.params
      end
    end
  end
end
