class CreateChecks < ActiveRecord::Migration[5.2]
  def change
    create_table :checks do |t|
    	t.text :room_id
    	t.integer :check_id, default: 1
      t.timestamps
    end
  end
end
