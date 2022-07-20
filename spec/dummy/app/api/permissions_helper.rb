require 'pundit'
module PermissionsHelper
  # Pundit won't import it's methods unless it sees a stub of ActionController's hide_action.
  def hide_action; end
  include Pundit::Authorization

end
