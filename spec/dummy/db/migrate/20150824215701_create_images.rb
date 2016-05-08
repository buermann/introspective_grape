class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.references :imageable, polymorphic: true, index: true
      t.attachment :file
      t.boolean :file_processing, null: false, default: false
      t.json   :meta
      t.string :source
      t.float  :lat
      t.float  :lng
      t.timestamp :taken_at
      t.timestamps null: false
    end
  end
end
