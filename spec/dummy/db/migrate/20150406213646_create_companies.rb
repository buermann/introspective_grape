class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.string :name, limit: 256, null: false
      t.string :short_name, limit: 10, null: false

      t.timestamps null: false
    end
    add_index :companies, :name, unique: true
  end
end
