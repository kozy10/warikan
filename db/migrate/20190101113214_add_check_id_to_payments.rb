class AddCheckIdToPayments < ActiveRecord::Migration[5.2]
  def change
  	add_column :payments, :check_id, :integer
  	remove_column :payments, :user_name, :text
  end
end
