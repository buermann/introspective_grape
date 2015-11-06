class CompanyPolicy < ApplicationPolicy
  def index?
    @user
  end

  def show?
    @user && @user.admin?(record)
  end

  def update?
    @user && @user.admin?(record)
  end

  def create?
    @user && @user.admin?(record)
  end

  def destroy?
    false
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.superuser?
        scope.all
      else
        scope.find( user.companies.map{|c| c.id} )
      end
    end
  end
end

