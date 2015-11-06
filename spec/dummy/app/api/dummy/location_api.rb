class Dummy::LocationAPI < IntrospectiveGrape::API

  default_includes Location, :child_locations, :gps, :beacons, :locatables

  exclude_actions LocationBeacon, :show,:create,:update,:destroy
  exclude_actions LocationGps, :show,:create,:update,:destroy

  restful Location, [:name, :kind,
    {gps_attributes: [:id, :lat, :lng, :alt, :_destroy]},
    {beacons_attributes: [:id, :company_id, :mac_address, :uuid, :major, :minor, :_destroy]},
  ]

  class Locatable < Grape::Entity
    expose :id, :locatable_id, :locatable_type, :updated_at, :created_at
  end

  class LocationBeaconEntity < Grape::Entity
    expose :id, :uuid, :major, :minor, :company_id, :mac_address, :created_at
  end

  class LocationGpsEntity < Grape::Entity
    expose :id, :lat, :lng, :alt, :updated_at
  end

  class ChildLocationEntity < Grape::Entity
    expose :id, :name, :kind, :created_at, :updated_at
  end

  class LocationEntity < Grape::Entity
    expose :id, :name, :kind,  :parent_location_id, :created_at, :updated_at
    expose :locatables,       using: Locatable
    expose :child_locations,  using: ChildLocationEntity
    expose :gps,              using: LocationGpsEntity
    expose :beacons,          using: LocationBeaconEntity
  end
end

