class AlertMailer < ApplicationMailer
	default from: 'usc.schedule.watcher@gmail.com'

	def alert_email(alert)
		@alert = alert
		@user = @alert.user
		mail(to: @user.email, subject: "Open seats in your course")
	end

	def set_alert_email(alert)
		@alert = alert
		@user = @alert.user
		mail(to: @user.email, subject: "Alert set")
	end
end
