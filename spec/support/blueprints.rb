require 'machinist/active_record'
require 'rufus/mnemo'

def _index # prevent unique string collisions over the test cycle
  @_uniq_idx ||= 0
  (@_uniq_idx+=1).to_s(36)
end

def syllable(length=-1)
  s = Rufus::Mnemo::from_integer(rand(8**5)+1) #+ _index
  s[0..length]
end

def word(max_syl=3)
  Array.new(1+rand(max_syl)).map { syllable }.join
end

def words(n=3)
  Array.new(n).collect { word }.join
end

def paragraph(n=25)
  words(n)
end

Company.blueprint do
  name       { words }
  short_name { syllable(10) }
end

User.blueprint do
  email       { "test-"+word(10)+'@springshot.com' }
  first_name  { word(4) }
  last_name   { word(5) }
  password    { 'abc12345' }
  confirmed_at { Time.now }
end

Role.blueprint {
  user_id       { User.first||User.make }
  ownable_id    { Company.first||Company.make }
  ownable_type  { 'Company' }
}

Locatable.blueprint {
  location { Location.make }
  locatable { Company.make }
}
Location.blueprint {
  name     { (65+rand(8)).chr+"1"}
  kind     { 'gate' }
  gps      { LocationGps.new(lat: 37.615223, lng: -122.389977 ) }
}
LocationBeacon.blueprint {
  location  { Location.make }
  company   { Company.make }
  mac_address { SecureRandom.hex(6) }
  # e.g. 2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6
  uuid { SecureRandom.hex(4)+'-'+SecureRandom.hex(2)+'-'+SecureRandom.hex(2)+'-'+SecureRandom.hex(2)+'-'+SecureRandom.hex(6) }
  major { rand(9999) }
  minor { rand(9999) }
}
LocationGps.blueprint {
  location { Location.make }
  # place the point randomly within about a mile radius of the TEST airport (LocationHelper)
  lat { 37.615223   + 0.01609*rand(0.1) * (rand(2) > 0 ? 1 : -1) }
  lng { -122.389977 + 0.01609*rand(0.1)*Math.cos(37.615223*Math::PI/180) * (rand(2) > 0 ? 1 : -1) }
  alt { 0 }
}

Project.blueprint {
  name  { words(2) }
  owner { Company.make }
  jobs { [Job.make, Job.make] }
  admins { [User.make] }
}
Job.blueprint {
  title { words(2) }
}
UserProjectJob.blueprint {
  user    { User.make }
  project { Project.make }
  job     { Job.make }
}
ProjectJob.blueprint {
  project { Project.make }
  job     { Job.make }
}


Team.blueprint {
  p = Project.make
  project { p }
  creator { p.admins.first }
  name { words(2) }
}
TeamUser.blueprint {
  t = Team.make
  t.project.users.push User.make(projects: [t.project])
  team { t }
  user { t.project.users.first }
}

