class CreateLocatables < ActiveRecord::Migration
  def change
    create_table :locatables do |t|
      t.references :location
      t.references :locatable, polymorphic: true, index: true

      t.timestamps null: false
    end
  end
end
