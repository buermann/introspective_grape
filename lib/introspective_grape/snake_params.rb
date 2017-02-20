module IntrospectiveGrape
  module SnakeParams
    def snake_parameters(child)
      child.before_validation do
        # We have to snake case the Rack params then re-assign @params to the
        # request.params, because of the I-think-very-goofy-and-inexplicable
        # way Grape interacts with both independently of each other
        (params.try(:with_snake_keys)||{}).each do |k,v|
          request.delete_param(k.camelize(:lower))
          request.update_param(k, v)
        end
        @params = request.params
      end
    end
  end
end
