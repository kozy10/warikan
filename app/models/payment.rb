class Payment < ApplicationRecord
	belongs_to :payer, :class_name => "User", foreign_key: 'payer_id', primary_key: 'user_id'
	belongs_to :room, foreign_key: 'room_id', primary_key: 'room_id'
end
