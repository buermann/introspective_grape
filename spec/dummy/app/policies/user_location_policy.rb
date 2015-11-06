class UserLocationPolicy < ApplicationPolicy
  def index?
    # This will need further specifications once the user-location relationship via
    # their companies is defined via project etc.
    @user && @user.company_admin?
  end

  def create?
    @user
  end
end

