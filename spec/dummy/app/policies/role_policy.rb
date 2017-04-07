class RolePolicy < ApplicationPolicy

  def index?
    @user
  end

  def show?
    @user.admin?(record.ownable)
  end

  def update?
    @user.admin?(record.ownable)
  end

  def create?
    @user.admin?(record.ownable)
  end

  def destroy?
    @user.admin?(record.ownable)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.superuser?
        scope.all
      else
        scope.where(ownable: user.admin_companies )
      end
    end
  end
end

