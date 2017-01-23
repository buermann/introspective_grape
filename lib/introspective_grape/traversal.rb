module IntrospectiveGrape::Traversal
  # For deeply nested endpoints we want to present the record being affected, these
  # methods traverse down from the parent instance to the child model associations
  # of the deeply nested route.

  def find_leaves(routes, record, params)
    # Traverse down our route and find the leaf's siblings from its parent, e.g.
    # project/#/teams/#/team_users ~> project.find.teams.find.team_users
    # (the traversal of the intermediate nodes occurs in find_leaf())
    return record if routes.size < 2 # the leaf is the root
    record = find_leaf(routes, record, params)
    if record 
      assoc  = routes.last
      if assoc.many? 
        leaves = record.send( assoc.reflection.name ).includes( default_includes(assoc.model) )
        verify_records_found(leaves, routes)
        leaves
      else 
        # has_one associations don't return a CollectionProxy and so don't support 
        # eager loading.
        record.send( assoc.reflection.name )
      end
    end
  end

  def verify_records_found(leaves, routes)
    unless (leaves.map(&:class) - [routes.last.model]).empty? 
      raise ActiveRecord::RecordNotFound.new("Records contain the wrong models, they should all be #{routes.last.model.name}, found #{records.map(&:class).map(&:name).join(',')}")
    end
  end

  def find_leaf(routes, record, params)
    return record unless routes.size > 1
    # For deeply nested routes we need to search from the root of the API to the leaf
    # of its nested associations in order to guarantee the validity of the relationship,
    # the authorization on the parent model, and the sanity of passed parameters.
    routes[1..-1].each_with_index do |r|
      if record && params[r.key]
        ref = r.reflection
        record = record.send(ref.name).where( id: params[r.key] ).first if ref
      end
    end

    verify_record_found(routes, params, record)
    record
  end

  def verify_record_found(routes, params, record)
    if params[routes.last.key] && record.class != routes.last.model
      raise ActiveRecord::RecordNotFound.new("No #{routes.last.model.name} with ID '#{params[routes.last.key]}'")
    end
  end

end
