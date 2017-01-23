class Role < AbstractAdapter
  belongs_to :user
  belongs_to :ownable, polymorphic: true

  validates_uniqueness_of :user_id, scope: [:ownable_type,:ownable_id], unless: "user_id.nil?", message: "user has already been assigned that role"
  OWNABLE_TYPES = %w(Company Project).freeze
  validates_inclusion_of :ownable_type, in: OWNABLE_TYPES

  delegate :email, to: :user,              allow_nil: true
  def attributes
    super.merge(email: email)
  end

  def self.grape_validations
    { ownable_type: { values: OWNABLE_TYPES } }
  end

  def self.ownable_assign_options(_model=nil)
    (Company.all + Project.all).map { |i| [ "#{i.class}: #{i.name}", "#{i.class}-#{i.id}"] }
  end

  def ownable_assign
    ownable.present? ? "#{ownable_type}-#{ownable_id}" : nil
  end

  def ownable_assign=(value)
    self.ownable_type,self.ownable_id = value.split('-')
  end

end
