module LocationHelper

  def rand_coords # generate a random point somewhere around the test airport
    l = LocationGps.make
    [l.lat,l.lng,l.alt]
  end

  def create_test_airport
    ###  build an airport with 8 terminals each with 3 gates along each cardinal and ordinal
    ###  axis, for two companies each with their own set of bluetooth beacons at every gate:
    ###
    ###                      (1)A B C          
    ###                          \|/      
    ###                      (8)H-*-D e.g.->(Terminal D with gates D1, D2, and D3) 
    ###                          /|\       
    ###                         G F E 

    @sprocketCo = Company.find_by_name("Sprockets") || Company.make(name:'Sprockets')
    @widgetCo   = Company.find_by_name("Widgets")   || Company.make(name:'Widgets')
    if @airport = Location.find_by_name("TEST")
      return @airport
    end

    @airport     = Location.new(name:'TEST',kind:'airport')
    @airport.companies.push @sprocketCo
    @airport.companies.push @widgetCo
    @airport.gps = LocationGps.new(lat: 37.615223, lng: -122.389977 )
    (1..8).each do |terminal|
      gate = (64+terminal).chr # A-H
      t = Location.new(name:"Terminal #{gate}",kind:'terminal')

      @airport.child_locations.push t

      (1..3).each do |number|

        lat, lng = [@airport.gps.lat, @airport.gps.lng]
        adj = 0.003*number # push successive gates ~0.21 miles out

        lat += (1..3).include?(terminal) ? adj : 0
        lat -= (5..7).include?(terminal) ? adj : 0

        adj *= Math.cos(37.615223*Math::PI/180) 
        lng += (3..5).include?( terminal) ? adj : 0
        lng -= [1,7,8].include?(terminal) ? adj : 0

        g = Location.new(name:"Gate #{gate}#{number}", kind:'gate')
        g.gps = LocationGps.make(location: g, lat: lat, lng: lng)
        g.beacons.push LocationBeacon.make(company: @sprocketCo, location: g)
        g.beacons.push LocationBeacon.make(company: @widgetCo, location: g)
        t.child_locations.push g
      end
    end
    @airport.save!
    @airport
  end
end
