class Company < AbstractAdapter
  has_many :roles, as: :ownable
  has_many :admins, through: :roles, source: :user
  accepts_nested_attributes_for :roles, allow_destroy: true
  
  has_many :beacons, class_name: 'LocationBeacon', dependent: :destroy
  has_many :locatables
  has_many :locations, through: :locatables, source: :locatable, source_type: 'Company'

  has_many :projects, foreign_key: :owner_id, dependent: :destroy, inverse_of: :owner

  validates_length_of :name, maximum: 256
  validates_length_of :short_name, maximum: 10

  def self.grape_validations
    {
      gizmos: { json: true },
      widgets: { json_array: true },
      sprockets: { json_hash: true }
    }
  end

  def gizmos=(json)
    JSON.parse(json)
  end

  def widgets=(json_array)
    JSON.parse(json_array)
  end

  def sprockets=(json_hash)
    JSON.parse(json_hash)
  end

end
