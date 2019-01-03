class Room < ApplicationRecord
	has_many :payments, foreign_key: 'room_id', primary_key: 'room_id'
end
