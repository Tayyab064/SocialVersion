class VerificationController < ApplicationController
	def verify_email
		if v_user = User.find_by_email_token(params[:token])
			if v_user.verified == true
				render json: {'message' => 'Email Already Verified!'} , status: :unprocessable_entity
			else
				v_user.update(verified: true , email_token: nil)
				render json: {'message' => 'Email Successfully Verified!'} , status: :ok
			end
		else
			render json: {'message' => 'Invalid Token!'} , status: :unauthorized
		end
	end
end
