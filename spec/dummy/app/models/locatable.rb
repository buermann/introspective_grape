class Locatable < AbstractAdapter
  belongs_to :location
  belongs_to :locatable, polymorphic: true

  validates_inclusion_of :locatable_type, in: %w(Company)
end
