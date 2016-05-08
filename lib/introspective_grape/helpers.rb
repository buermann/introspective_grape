module IntrospectiveGrape::Helpers
  def authentication_method=(method)
    # IntrospectiveGrape::API.authentication_method=
    @authentication_method = method
  end

  def authentication_method(context)
    # Default to "authenticate!" or as grape docs once suggested, "authorize!"
    if @authentication_method 
      @authentication_method
    elsif context.respond_to?('authenticate!')
      'authenticate!'
    elsif context.respond_to?('authorize!')
      'authorize!'
    end
  end

  def exclude_actions(model, *args)
    @exclude_actions ||= {}
    @@api_actions ||= [:index,:show,:create,:update,:destroy,nil]
    raise "#{model.name} defines invalid exclude_actions: #{args-@@api_actions}" if (args.flatten-@@api_actions).present?
    @exclude_actions[model.name] = args.present? ? args.flatten : @exclude_actions[model.name] || []
  end

  def default_includes(model, *args)
    @default_includes ||= {}
    @default_includes[model.name] = args.present? ? args.flatten : @default_includes[model.name] || []
  end
  
  def whitelist(whitelist=nil)
    return @whitelist if !whitelist
    @whitelist = whitelist
  end

  def skip_presence_validations(fields=nil)
    return @skip_presence_fields||[] if !fields
    @skip_presence_fields = [fields].flatten
  end


end


