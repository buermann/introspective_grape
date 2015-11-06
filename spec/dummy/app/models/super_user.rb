#require 'activerecord-tableless'
class SuperUser < AbstractAdapter
  # An empty ActiveRecord association for the polymorphic identity on Role.
  # We could also just create a SuperUser table with one record to do this...
  has_no_table :database => :pretend_success

  def name
    'Admin'
  end

end
