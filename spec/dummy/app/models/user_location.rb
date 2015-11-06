class UserLocation < AbstractAdapter
  belongs_to :user
  belongs_to :location
  belongs_to :detectable, polymorphic: true

  validates_inclusion_of :detectable_type, in: %w(LocationBeacon LocationGps)

  default_scope { includes(:detectable).order("created_at desc") } 

  def coords=(c) # convenience method to set coordinates by an array of [lat,lng,alt]
    self.lat = c[0]
    self.lng = c[1]
    self.alt = c[2]
  end

  def beacon 
    detectable.is_a?(LocationBeacon) ? detectable : {}
  end

  def distance 
    if location.gps && lat && lng
      location.gps.distance_from(lat,lng)
    else 
      nil
    end
  end

end
