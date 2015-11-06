class Role < AbstractAdapter
  belongs_to :user
  belongs_to :ownable, polymorphic: true

  validates_uniqueness_of :user_id, scope: [:ownable_type,:ownable_id], unless: "user_id.nil?", message: "user has already been assigned that role"
  validates_inclusion_of :ownable_type, in: ['SuperUser', 'Company', 'Project']

  delegate :email, to: :user,              allow_nil: true
  def attributes
    super.merge(email: email)
  end

  def ownable
    # return the SuperUser null object
    ownable_type == 'SuperUser' ? SuperUser.new : super
  end

  def self.ownable_assign_options(model=nil)
    ([SuperUser.new] + Company.all + Project.all).map { |i| [ "#{i.class}: #{i.name}", "#{i.class}-#{i.id}"] }
  end

  def ownable_assign
    ownable.present? ? "#{ownable_type}-#{ownable_id}" : nil
  end

  def ownable_assign=(value)
    self.ownable_type,self.ownable_id = value.split('-')
  end

end
