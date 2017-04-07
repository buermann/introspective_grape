class AddUserAuthenticationToken < ActiveRecord::Migration
  def change
    add_column :users, :authentication_token, :string
    add_index  :users, :authentication_token, :unique => true
  end

  def down
    remove_index  :users, :authentication_token
    remove_column :users, :authentication_token
  end
end
