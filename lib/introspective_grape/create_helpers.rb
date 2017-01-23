module IntrospectiveGrape
  module CreateHelpers

    def add_new_records_to_root_record(dsl, routes, params, model)
      dsl.authorize model, :create?
      ActiveRecord::Base.transaction do
        old = find_leaves(routes, model, params)
        model.update_attributes( dsl.send(:safe_params,params).permit(whitelist) )
        new = find_leaves(routes, model, params)
        old.respond_to?(:size) ? new-old : new
      end
    end

    def create_new_record(dsl, routes, params)
      model = routes.first.model.new( dsl.send(:safe_params,params).permit(whitelist) )
      dsl.authorize model, :create?
      model.save!
      find_leaves(routes, model.reload, params)
    end

  end
end
