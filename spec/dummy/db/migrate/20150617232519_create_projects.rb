class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.integer :owner_id, references: :companies, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
