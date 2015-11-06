class Location < AbstractAdapter
  has_many :locatables, dependent: :destroy
  has_many :companies, through: :locatables, source: :locatable, source_type: 'Company'

  has_many :beacons, class_name: 'LocationBeacon', dependent: :destroy
  has_one  :gps,     class_name: 'LocationGps',    dependent: :destroy
  delegate :lat,:lng,:alt, to: :gps

  belongs_to :parent_location, foreign_key: :parent_location_id, class_name: 'Location', inverse_of: :child_locations
  has_many   :child_locations, foreign_key: :parent_location_id, class_name: 'Location', dependent: :destroy, inverse_of: :parent_location

  has_many :user_locations, dependent: :destroy

  # isn't this list going to be kinda long? are there any reasonable constraints to put
  # on this random bit of metadata?
  validates_inclusion_of :kind, in: %w(airport terminal gate plane)

  accepts_nested_attributes_for :child_locations, allow_destroy: true
  accepts_nested_attributes_for :gps,             allow_destroy: true
  accepts_nested_attributes_for :beacons,         allow_destroy: true

  def coords
    [gps.lat, gps.lng, gps.alt]
  end

end
