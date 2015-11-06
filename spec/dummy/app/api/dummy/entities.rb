# Grape Entity monkey patch to ensure that all keys are exposed as camelCased instead of the actual Ruby snake_case names.
# Note that the keys are not touched if the :as option is used, so
#   expose :some_name, :as => 'some_name'
# will remain snake_cased

#class Grape::Entity
#  protected
#  def self.key_for(attribute)
#    (exposures[attribute.to_sym][:as] || attribute).to_s.camelize(:lower).to_sym
#  end
#end

module Dummy::Entities

  # base class for entities
  class DummyEntity < Grape::Entity
    # common formatters can go here
  end

  # User entities
  class User < DummyEntity
    expose :id, :email, :first_name, :last_name, :avatar_url, :authentication_token
  end
end

