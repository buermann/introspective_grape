class AddTestData < ActiveRecord::Migration[5.2]
  def change
    User.create(email: 'test@test.com', superuser: true, authentication_token: '1234567890', first_name: "First", last_name: "Last")
  end
end
