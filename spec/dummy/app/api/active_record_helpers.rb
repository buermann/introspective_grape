# Duck-type some helper class methods into our ActiveRecord models to
# allow us to configure API behaviors granularly, at the model level.
class ActiveRecord::Base
  class << self
    @@api_actions ||= [:index,:show,:create,:update,:destroy,nil]
    def api_actions; @@api_actions; end

    def exclude_actions(*args) # Do not define endpoints for these actions
      raise "#{self.name} defines invalid exclude_actions: #{args-@@api_actions}" if (args.flatten-@@api_actions).present?
      @exclude_actions = args.present? ? args.flatten : @exclude_actions || []
    end

    def default_includes(*args) # Eager load these associations.
      @default_includes = args.present? ? args.flatten : @default_includes || []
    end
  end
end
