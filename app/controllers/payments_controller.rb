class PaymentsController < ApplicationController

	def new
		@payment = Payment.new
	end

	def create
		@payment = Payment.new(payment_params)
		@payment.check_id = @payment.room.check_id
		@payment.save
		flash[:notice] = "#{@payment.title}が追加されました。"
		redirect_to new_payment_path
	end

	private
		def payment_params
			params.require(:payment).permit(:title, :price, :payer_id, :room_id, :check_id)
		end
end