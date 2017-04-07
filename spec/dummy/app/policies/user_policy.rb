class UserPolicy < ApplicationPolicy

  def sessions?
    true
  end

end

