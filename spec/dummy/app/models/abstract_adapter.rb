class AbstractAdapter < ActiveRecord::Base
  self.abstract_class = true

  class << self
    def human_attribute_name(attr, options = {})
      # The default formatting of validation errors sucks, this helps a little syntatically:
      super.titleize+":"
    end

  end

end

