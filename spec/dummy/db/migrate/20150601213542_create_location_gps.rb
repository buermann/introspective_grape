class CreateLocationGps < ActiveRecord::Migration
  def change
    create_table :location_gps do |t|
      t.references :location, index: true, foreign_key: true
      t.float :lat, null: false
      t.float :lng, null: false
      t.float :alt, default: 0

      t.timestamps null: false
    end
  end
end
