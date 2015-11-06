class AddPasswordToProject < ActiveRecord::Migration
  def change
    add_column :projects, :default_password, :string
  end
end
