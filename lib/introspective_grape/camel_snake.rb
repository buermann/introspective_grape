require 'active_support/inflections'
module IntrospectiveGrape::CamelSnake
  def snake_keys(data)
    if data.kind_of? Array
      data.map { |v| snake_keys(v) }
    elsif data.kind_of? Hash
      Hash[data.map {|k, v| [k.to_s.underscore, snake_keys(v)] }]
    else
      data
    end
  end

  def camel_keys(data)
    if data.kind_of? Array
      data.map { |v| camel_keys(v) }
    elsif data.kind_of?(Hash)
      Hash[data.map {|k, v| [k.to_s.camelize(:lower), camel_keys(v)] }]
    else
      data
    end
  end
end
