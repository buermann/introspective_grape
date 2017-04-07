class CreateLocationBeacons < ActiveRecord::Migration
  def change
    create_table :location_beacons do |t|
      t.references :location
      t.references :company, null: false
      t.string  :mac_address, limit: 12
      t.string  :uuid, null: false, limit: 32
      t.integer :major, null: false
      t.integer :minor, null: false

      t.timestamps null: false
    end
    add_index :location_beacons, [:company_id,:uuid,:major,:minor], name: "index_location_beacons_unique_company_identifier", unique: true
  end
end
