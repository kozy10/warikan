class CreateRooms < ActiveRecord::Migration[5.2]
  def change
    create_table :rooms do |t|
    	t.text :room_id
    	t.integer :check_id, default: 0
    	t.integer :number_of_members, default: 0
      t.timestamps
    end
  end
end
