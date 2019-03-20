module IntrospectiveGrape
  module CreateHelpers

    def add_new_records_to_root_record(dsl, routes, params, model)
      dsl.send(:authorize, model, :create?)
      ActiveRecord::Base.transaction do
        old = find_leaves(routes, model, params)
        model.update_attributes( dsl.send(:safe_params,params).permit(whitelist) )
        new = find_leaves(routes, model, params)
        old.respond_to?(:size) ? new-old : new
      end
    end

    def create_new_record(dsl, routes, params)
      model = routes.first.model.new( dsl.send(:safe_params,params).permit(whitelist) )
      dsl.send(:authorize, model, :create?)
      model.save!

      # reload the model with eager loading
      default_includes = routes.first.klass.default_includes(routes.first.model)
      model = model.class.includes(default_includes).find(model.id) if model.persisted?

      find_leaves(routes, model, params)
    end

  end
end
