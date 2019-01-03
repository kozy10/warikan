class AddDefaultCheckIdToPaymentsAndRooms < ActiveRecord::Migration[5.2]
  def change
  	change_column :payments, :check_id, :integer, default: 1
  	change_column :rooms, :check_id, :integer, default: 1
  end
end
