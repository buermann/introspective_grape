class LocationPolicy < ApplicationPolicy
  def index?
    @user
  end

  def show?
    @user
  end

  def update?
    @user && @user.superuser?
  end

  def create?
    @user && @user.superuser?
  end

  def destroy?
    @user && @user.superuser?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(parent_location_id: nil)
    end
  end

end

