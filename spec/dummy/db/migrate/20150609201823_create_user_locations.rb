class CreateUserLocations < ActiveRecord::Migration
  def change
    create_table :user_locations do |t|
      t.references :user, index: true, foreign_key: true
      t.references :location, index: true, foreign_key: true
      t.references :detectable, polymorphic: true, index: true
      t.float :lat
      t.float :lng
      t.float :alt

      t.timestamps null: false
    end
  end
end
