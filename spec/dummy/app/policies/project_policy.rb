class ProjectPolicy < ApplicationPolicy
  def index?
    @user
  end

  def project_user?
    project_manager? || record.users.include?(@user)
  end

  def project_manager?
    @user.superuser? || @user.all_admin_projects.include?(record)
  end

  def show?
    @user && project_user?
  end

  def update?
    @user && project_manager?
  end

  def create?
    @user && project_manager?
  end

  def destroy?
    @user && project_manager?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.superuser?
        scope.all
      elsif user.project_admin?
        scope.find( (user.all_admin_projects+user.projects).map(&:id) )
      else
        scope.find( user.projects )
      end
    end
  end
end

