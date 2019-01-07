class PaymentsController < ApplicationController

	def new
		@payment = Payment.new
	end

	def create
		@payment = Payment.new(payment_params)
		@payment.check_id = @payment.room.check_id
		if @payment.save
			if params[:select_user]
				redirect_to edit_payment_path(@payment)
			else
				flash[:notice] = "#{@payment.title}が追加されました。"
				redirect_to new_payment_path
			end
		else
			flash[:notice] = "支払いが追加できません。"
			redirect_to new_payment_path
		end
	end

	def edit
		@payment = Payment.find(params[:id])
		@user = User.where(room_id: @payment.room_id)
	end

	def update
	end

	private
		def payment_params
			params.require(:payment).permit(:title, :price, :payer_id, :room_id, :check_id)
		end
end