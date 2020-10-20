module IntrospectiveGrape
  def self.configure
    self.config ||= Configuration.new
    yield config
  end

  class Configuration
    attr_accessor :camelize_parameters, :skip_object_reload

    def initialize
      @camelize_parameters = true
      @skip_object_reload  = false
    end
  end
end
