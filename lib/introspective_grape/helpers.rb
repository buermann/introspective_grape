module IntrospectiveGrape::Helpers
  API_ACTIONS = [:index,:show,:create,:update,:destroy].freeze
  def authentication_method=(method)
    # IntrospectiveGrape::API.authentication_method=
    @authentication_method = method
  end

  attr_accessor :pagination

  def paginate(args={})
    @pagination = args
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
    @exclude_actions ||= {}; @exclude_actions[model.name] ||= []
    args.flatten!
    args = API_ACTIONS if args.include?(:all)
    args = []          if args.include?(:none)

    undefined_actions = args.compact-API_ACTIONS
    raise "#{model.name} defines invalid actions: #{undefined_actions}" if undefined_actions.present?

    @exclude_actions[model.name] = args.present? ? args.compact : @exclude_actions[model.name] || []
  end

  def include_actions(model, *args)
    @exclude_actions ||= {}; @exclude_actions[model.name] ||= []
    @exclude_actions[model.name] = API_ACTIONS-exclude_actions(model, args)
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


