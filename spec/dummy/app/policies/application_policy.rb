class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user   = user
    @record = record
  end

  def index?
    @user.superuser?
  end

  def show?
    @user.superuser? || scope.where(:id => record.id).exists?
  end

  def create?
    @user.superuser?
  end

  def update?
    @user.superuser?
  end

  def destroy?
    @user.superuser?
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end

end

