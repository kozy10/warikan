class UsersController < ApplicationController

	def new
		@user = User.new
	end

	def create
		@user = User.new(user_params)
		if @user.save
			room = Room.find_by(room_id: @user.room_id)
			room.number_of_members += 1
			room.save
			flash[:notice] = "参加しました。"
			redirect_to users_complete_path
		else
			flash[:notice] = "すでに参加しています。"
			redirect_to users_error_path
		end
	end

	def complete
	end

	def error
	end

	private
		def user_params
			params.require(:user).permit(:user_id, :room_id, :name)
		end
end