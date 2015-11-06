class AddRoleUserConstraint < ActiveRecord::Migration
  def up
    change_column :roles, :user_id, :integer, null: false
  end

  def down 
    change_column :roles, :user_id, :integer, null: true
  end
end
