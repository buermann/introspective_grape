class AbstractAdapter < ActiveRecord::Base
  primary_abstract_class

	class << self
		def inherited(klass)
			super
			klass.validates_by_schema
		end

		def human_attribute_name(attr, options = {})
			# The default formatting of validation errors sucks, this helps a little syntatically:
			super.titleize+":"
		end
	end
end

