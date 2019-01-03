class User < ApplicationRecord
	validates :user_id, :uniqueness => {:scope => :room_id}
	has_many :payments, foreign_key: 'payer_id', primary_key: 'user_id'
end
