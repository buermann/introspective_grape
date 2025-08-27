class Route
  attr_accessor(*%i[klass name param model many key swagger_key reflection])

  def initialize(attrs = {})
    attrs.each { |key, value| instance_variable_set("@#{key}", value) }
  end

  def many?
    many ? true : false
  end
end
