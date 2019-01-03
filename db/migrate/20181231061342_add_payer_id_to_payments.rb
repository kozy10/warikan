class AddPayerIdToPayments < ActiveRecord::Migration[5.2]
  def change
  	add_column :payments, :payer_id, :text
  end
end
