class UsersController < ApplicationController
	before_filter :restrict_access, except: [:create , :signin ]
	
	def create
		if user = User.find_by_email(params[:user][:email])
			render json: {'message' => 'Already signedup!'} , status: :ok
		else
			if params[:user][:password].blank?
				ident = params[:user][:identities_attributes]['0']
				p ident
				if ident[:provider].present? && ident[:uid].present? && ident[:token].present? 
					if user = User.create(user_params)
						user.update(verified: true)
						render json: user.identities.first ,  status: :created
					else
						render json: user.errors, status: :unprocessable_entity
					end
				else
					render json: {'message' => 'Params are missing!'} , status: :unprocessable_entity
				end
			else
				pass = BCrypt::Password.create(params[:user][:password])
				user = User.create(:email => params[:user][:email] , :password => pass )
				user.generate_email_token
				user.save
				identity = Identity.new(:provider => 'Social' , :user_id => user.id)
				identity.generate_token
			    identity.save
				render json: identity, status: :created
				UserMailer.welcome_email(user).deliver_later
			end
		end
	end

	def signin
		if user = User.find_by_email(params[:user][:email])
			if params[:user][:password].blank?
				ident = params[:user][:identities_attributes]['0']
				if ident[:provider].present? && ident[:uid].present? && ident[:token].present? 
					if identity = user.identities.find_by_provider(ident[:provider])
						if identity.uid == ident[:uid]
							user.identities.each do |iden|
								iden.update_attributes(:token => nil)
							end
							identity.update_attributes(:token => ident[:token])
				    		render json: identity ,  status: :ok
				    	else
				    		render json: {'message' => 'Invalid user id'} , status: :unprocessable_entity
				    	end
					else
						user.identities.each do |iden|
							iden.update_attributes(:token => nil)
						end
						identity = user.identities.create(user_signin_params["identities_attributes"]['0'])
						#:provider => params[:provider], :uid => params[:uid], :url => params[:url], :token => params[:token], :expires_at => params[:expires_at] , :user_id => @user.id
						render json: identity , status: :created
					end
				else
					render json: {'message' => 'Params are missing!'} , status: :unprocessable_entity
				end
			else
				if user.password.present?
					if BCrypt::Password.new(user.password)  == params[:user][:password]
						if identity = user.identities.find_by_provider('Social')
							user.identities.each do |iden|
								iden.update_attributes(:token => nil)
							end
							identity.generate_token
				    		identity.save
				    		render json: identity , status: :ok
						else
							render json: {'message' => 'Failed to signin'} , status: :bad_request
						end
					else
						render json: {'message' => 'Invalid password!'} , status: :unauthorized
					end
				else
					render json: {'message' => 'Login to Social Sites'} , status: :bad_request
				end
			end
		else
			render json: {'message' => 'Kindly signup!'} , status: :unauthorized
		end
	end

	def signout
		@current_user.identities.each do |identity|
			if identity.token.present?
				identity.token = nil
				identity.save
			end
		end
		head :no_content
	end


	private
	def user_params
		params.require(:user).permit(:first_name, :last_name, :email, :password, :gender, identities_attributes: [:provider, :uid, :url, :token, :expires_at])
	end

	def user_signin_params
		params.require(:user).permit(:email, :password, identities_attributes: [:provider, :uid, :url, :token, :expires_at])
	end

end
