class AddUserNameToPaymemts < ActiveRecord::Migration[5.2]
  def change
  	add_column :payments, :user_name, :text
  end
end
