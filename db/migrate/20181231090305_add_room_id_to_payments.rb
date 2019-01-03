class AddRoomIdToPayments < ActiveRecord::Migration[5.2]
  def change
  	add_column :payments, :room_id, :text
  end
end
