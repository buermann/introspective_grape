class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.integer :user_id
      t.references :ownable, polymorphic: true, index: true

      t.timestamps null: false
    end
    add_index :roles, [:user_id,:ownable_type,:ownable_id], unique: true
  end

end
