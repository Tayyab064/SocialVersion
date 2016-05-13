class UserMailer < ApplicationMailer
	def welcome_email(user)
		@user = user
		@url  = 'http://localhost:3000'
		mail(to: @user.email, subject: 'Social', body: 'Welcome User. Please click on link to confirm email: ' + @url + '/user/email/verify/' + @user.email_token )
	end
end
