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
		else
			flash[:notice] = "参加できません。"
		end
		redirect_to new_user_path
	end

	private
		def user_params
			params.require(:user).permit(:user_id, :room_id, :name)
		end
end